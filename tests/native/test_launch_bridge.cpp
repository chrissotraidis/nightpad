#include "../../vendor/nightfire/src/common/launchInfo.h"

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static char g_image[32];
static uint32_t g_page[0x300];
static unsigned g_bytes;
static int g_callbackCount;

static bool CaptureRequest(const char *image, const void *page, unsigned bytes) {
    snprintf(g_image, sizeof(g_image), "%s", image);
    memcpy(g_page, page, sizeof(g_page));
    g_bytes = bytes;
    g_callbackCount++;
    return true;
}

struct Request {
    const char *image;
    uint32_t page[0x300];
};

static void *RequestTransition(void *argument) {
    Request *request = static_cast<Request *>(argument);
    XLaunchNewImageA(const_cast<char *>(request->image), request->page);
    return reinterpret_cast<void *>(1);   // unreachable when the coordinator owns the request
}

int main() {
    char directory[] = "/tmp/nightpad-launch-bridge.XXXXXX";
    if (mkdtemp(directory) == nullptr || chdir(directory) != 0) {
        perror("mkdtemp/chdir");
        return 1;
    }

    Request request = {};
    request.image = "DRIVING.XBE";
    for (unsigned i = 0; i < 0x300; ++i) {
        request.page[i] = 0x4e500000u | i;
    }
    LaunchInfo_SetRequestHook(CaptureRequest);

    pthread_t thread;
    if (pthread_create(&thread, nullptr, RequestTransition, &request) != 0) {
        return 2;
    }
    void *result = nullptr;
    pthread_join(thread, &result);

    FILE *file = fopen("psiLaunch.bin", "rb");
    if (file == nullptr) {
        fprintf(stderr, "launch page was not written\n");
        return 3;
    }
    uint32_t page[0x300] = {};
    size_t read = fread(page, 4, 0x300, file);
    fclose(file);

    bool ok = result == nullptr && g_callbackCount == 1 && strcmp(g_image, "DRIVING.XBE") == 0 &&
              g_bytes == 0x300 * 4 && read == 0x300 && memcmp(g_page, request.page, sizeof(g_page)) == 0 &&
              memcmp(page, request.page, sizeof(page)) == 0;
    printf("launch bridge: %s; image=%s bytes=%u callback=%d thread-exited=%s page=%s\n",
           ok ? "PASS" : "FAIL", g_image, g_bytes, g_callbackCount, result == nullptr ? "yes" : "no",
           read == 0x300 && memcmp(page, request.page, sizeof(page)) == 0 ? "identical" : "different");
    return ok ? 0 : 4;
}

