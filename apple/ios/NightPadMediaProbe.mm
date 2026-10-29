#import "NightPadMediaProbe.h"

#if NIGHTPAD_HAS_FFMPEG

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

static bool DecodeOne(AVCodecContext *codec, AVPacket *packet, AVFrame *frame) {
  if (avcodec_send_packet(codec, packet) < 0) {
    return false;
  }
  int result = avcodec_receive_frame(codec, frame);
  return result == 0;
}

NSString *NightPadRunMediaProbe(void) {
  NSString *path = [[[NSBundle mainBundle] bundlePath]
      stringByAppendingPathComponent:@"fixture.xmv"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return @"Media fixture missing";
  }
  AVFormatContext *format = nullptr;
  if (avformat_open_input(&format, path.fileSystemRepresentation, nullptr, nullptr) < 0) {
    return @"FFmpeg could not open the XMV fixture";
  }
  NSString *failure = nil;
  AVCodecContext *video = nullptr;
  AVCodecContext *audio = nullptr;
  AVPacket *packet = av_packet_alloc();
  AVFrame *frame = av_frame_alloc();
  if (avformat_find_stream_info(format, nullptr) < 0) {
    failure = @"FFmpeg could not inspect the XMV fixture";
  }
  int videoIndex = -1;
  int audioIndex = -1;
  if (failure == nil) {
    for (unsigned i = 0; i < format->nb_streams; ++i) {
      if (format->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO && videoIndex < 0) {
        videoIndex = (int)i;
      } else if (format->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO && audioIndex < 0) {
        audioIndex = (int)i;
      }
    }
    if (videoIndex < 0 || audioIndex < 0) {
      failure = @"XMV fixture is missing video or audio";
    }
  }
  if (failure == nil) {
    const AVCodec *videoCodec =
        avcodec_find_decoder(format->streams[videoIndex]->codecpar->codec_id);
    const AVCodec *audioCodec =
        avcodec_find_decoder(format->streams[audioIndex]->codecpar->codec_id);
    if (videoCodec == nullptr || audioCodec == nullptr) {
      failure = @"Required FFmpeg decoders are absent";
    } else {
      video = avcodec_alloc_context3(videoCodec);
      audio = avcodec_alloc_context3(audioCodec);
      if (video == nullptr || audio == nullptr ||
          avcodec_parameters_to_context(video, format->streams[videoIndex]->codecpar) < 0 ||
          avcodec_parameters_to_context(audio, format->streams[audioIndex]->codecpar) < 0 ||
          avcodec_open2(video, videoCodec, nullptr) < 0 ||
          avcodec_open2(audio, audioCodec, nullptr) < 0) {
        failure = @"FFmpeg could not open the required decoders";
      }
    }
  }
  bool gotVideo = false;
  bool gotAudio = false;
  for (int packets = 0; failure == nil && packets < 64 && !(gotVideo && gotAudio); ++packets) {
    if (av_read_frame(format, packet) < 0) {
      failure = @"XMV ended before both media frames decoded";
      break;
    }
    if (packet->stream_index == videoIndex && !gotVideo) {
      gotVideo = DecodeOne(video, packet, frame);
    } else if (packet->stream_index == audioIndex && !gotAudio) {
      gotAudio = DecodeOne(audio, packet, frame);
    }
    av_packet_unref(packet);
  }
  if (failure == nil && (!gotVideo || !gotAudio)) {
    failure = @"FFmpeg did not produce both media frames";
  }
  av_frame_free(&frame);
  av_packet_free(&packet);
  avcodec_free_context(&video);
  avcodec_free_context(&audio);
  avformat_close_input(&format);
  return failure ?: @"FFmpeg XMV video/audio: PASS";
}

#else

NSString *NightPadRunMediaProbe(void) {
  return @"FFmpeg media probe not built";
}

#endif

