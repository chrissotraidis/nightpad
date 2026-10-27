cmake_minimum_required(VERSION 3.22)
project(NightPadPlatformProbe LANGUAGES C CXX OBJCXX)

get_filename_component(ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
get_filename_component(NIGHTFIRE "${ROOT}/vendor/nightfire" ABSOLUTE)
string(TOLOWER "${CMAKE_OSX_SYSROOT}" SDK_ROOT_LOWER)
if(SDK_ROOT_LOWER MATCHES "iphonesimulator")
  set(NIGHTPAD_SDK iphonesimulator)
elseif(SDK_ROOT_LOWER MATCHES "iphoneos")
  set(NIGHTPAD_SDK iphoneos)
else()
  message(FATAL_ERROR "NightPad requires the iPhoneOS or iPhoneSimulator SDK")
endif()

add_executable(NightPadProbe MACOSX_BUNDLE
  NightPadPlatformProbe.mm
  NightPadMetalProbe.mm
  NightPadMediaProbe.mm
  "${NIGHTFIRE}/src/driving/devtools/GameWindowTest.cpp"
  "${NIGHTFIRE}/src/driving/platform/GameWindow.cpp"
  "${NIGHTFIRE}/src/driving/platform/HostPosix.cpp")

add_library(nightpad_core STATIC
  ../shared/NightPadPaths.cpp
  ../shared/NightPadGameDataImport.cpp
  ../shared/NightPadDiagnostics.cpp
  ../shared/NightPadInput.cpp
  ../shared/NightPadControllerSlots.cpp
  ../shared/NightPadSettings.cpp
  ../shared/NightPadTouchInput.cpp
  ../shared/NightPadTouchLayout.cpp)
target_include_directories(nightpad_core PUBLIC ../shared)
target_compile_features(nightpad_core PUBLIC cxx_std_20)
target_compile_options(nightpad_core PRIVATE -fno-exceptions)

add_executable(NightPadShell MACOSX_BUNDLE
  main.mm
  NightPadShellViewController.mm
  NightPadDiagnosticsViewController.mm
  NightPadAboutViewController.mm
  NightPadTouchLayoutViewController.mm
  NightPadControlsHelpViewController.mm
  NightPadTouchControlsView.mm
  NightPadControllerAuthority.mm
  NightPadControllerRumble.mm
  NightPadGameInput.mm
  NightPadEngineHost.mm)
target_compile_features(NightPadShell PRIVATE cxx_std_20)
target_compile_options(NightPadShell PRIVATE -fobjc-arc)
target_compile_definitions(NightPadShell PRIVATE $<$<CONFIG:Debug>:DEBUG=1>)
target_link_libraries(NightPadShell PRIVATE nightpad_core
  "-framework UIKit" "-framework Foundation" "-framework CoreGraphics" "-framework UniformTypeIdentifiers"
  "-framework GameController" "-framework CoreHaptics")
set(NIGHTPAD_ENGINE_ARCHIVE "" CACHE FILEPATH "Combined engine archive from build_combined_engine_link.sh")
if(NIGHTPAD_ENGINE_ARCHIVE)
  target_compile_definitions(NightPadShell PRIVATE NIGHTPAD_HAS_ENGINE=1)
  target_include_directories(NightPadShell PRIVATE "${NIGHTFIRE}/src")
  target_link_options(NightPadShell PRIVATE -Wl,-no_fixup_chains
    "-Wl,-force_load,${NIGHTPAD_ENGINE_ARCHIVE}"
    "-Wl,-u,_NightPadDrivingEngineStart")
  target_link_libraries(NightPadShell PRIVATE
    "${NIGHTPAD_ENGINE_ARCHIVE}"
    "${NIGHTPAD_SDL_LIB}"
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavformat.a"
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavcodec.a"
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavutil.a"
    "${NIGHTPAD_SPIRV_ROOT}/libspirv-cross-msl.a"
    "${NIGHTPAD_SPIRV_ROOT}/libspirv-cross-glsl.a"
    "${NIGHTPAD_SPIRV_ROOT}/libspirv-cross-core.a"
    -lm
    "-framework CoreMedia" "-framework CoreVideo" "-framework CoreAudio"
    "-framework AudioToolbox" "-framework AVFoundation" "-framework CoreBluetooth"
    "-framework CoreMotion" "-framework GameController" "-framework Metal"
    "-framework OpenGLES" "-framework QuartzCore" "-weak_framework CoreHaptics")
else()
  target_compile_definitions(NightPadShell PRIVATE NIGHTPAD_HAS_ENGINE=0)
endif()
set_target_properties(NightPadShell PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/NightPadShellInfo.plist.in"
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "local.nightpad.shell"
  XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO")

set_source_files_properties("${NIGHTFIRE}/src/driving/devtools/GameWindowTest.cpp"
  PROPERTIES COMPILE_DEFINITIONS "main=NightfireGameWindowTestMain")
target_compile_definitions(NightPadProbe PRIVATE
  NIGHTFIRE_WINDOW_BASE=0x100000000
  NIGHTFIRE_X87=0
  NIGHTFIRE_SSE=0)
target_compile_options(NightPadProbe PRIVATE
  -ffp-contract=off -fms-extensions -fno-exceptions
  -Wno-invalid-offsetof -Wno-ignored-attributes
  $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>)
target_include_directories(NightPadProbe PRIVATE "${NIGHTFIRE}/src/driving")
find_package(Threads REQUIRED)
target_link_libraries(NightPadProbe PRIVATE Threads::Threads
  nightpad_core
  "-framework UIKit" "-framework Foundation" "-framework Metal" "-framework QuartzCore")
set(NIGHTPAD_FFMPEG_ROOT "" CACHE PATH "iPhoneOS FFmpeg prefix built by scripts/build_ffmpeg_ios.sh")
if(NIGHTPAD_FFMPEG_ROOT)
  if(NOT EXISTS "${NIGHTPAD_FFMPEG_ROOT}/include/libavformat/avformat.h")
    message(FATAL_ERROR "NIGHTPAD_FFMPEG_ROOT has no FFmpeg headers")
  endif()
  target_compile_definitions(NightPadProbe PRIVATE NIGHTPAD_HAS_FFMPEG=1)
  target_include_directories(NightPadProbe PRIVATE "${NIGHTPAD_FFMPEG_ROOT}/include")
  target_link_libraries(NightPadProbe PRIVATE
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavformat.a"
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavcodec.a"
    "${NIGHTPAD_FFMPEG_ROOT}/lib/libavutil.a")
else()
  target_compile_definitions(NightPadProbe PRIVATE NIGHTPAD_HAS_FFMPEG=0)
endif()
set(NIGHTPAD_MEDIA_FIXTURE "" CACHE FILEPATH "Private XMV fixture for the development probe")
if(NIGHTPAD_MEDIA_FIXTURE)
  set_source_files_properties("${NIGHTPAD_MEDIA_FIXTURE}" PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources)
  target_sources(NightPadProbe PRIVATE "${NIGHTPAD_MEDIA_FIXTURE}")
endif()
set_target_properties(NightPadProbe PROPERTIES
  CXX_STANDARD 20 CXX_STANDARD_REQUIRED YES
  OBJCXX_STANDARD 20 OBJCXX_STANDARD_REQUIRED YES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in"
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "local.nightpad.platform-probe"
  XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO")

