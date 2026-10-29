#include "common/gfx/presentationRect.h"
#include <assert.h>
#include <initializer_list>
#include <stdint.h>
#include <stdio.h>

static void Expect(PresentationRect r, uint32_t x, uint32_t y, uint32_t w, uint32_t h) {
    assert(r.x == x && r.y == y && r.w == w && r.h == h);
}

int main() {
    Expect(PresentationFit({0, 0, 1920, 1080}, true), 0, 0, 1920, 1080);
    Expect(PresentationFit({0, 0, 1920, 1080}, false), 240, 0, 1440, 1080);
    Expect(PresentationFit({0, 0, 2048, 1536}, true), 0, 192, 2048, 1152);
    Expect(PresentationFit({0, 0, 2048, 1536}, false), 0, 0, 2048, 1536);
    Expect(PresentationFit({0, 0, 1080, 1920}, false), 0, 555, 1080, 810);
    Expect(PresentationFit({12, 18, 0, 300}, false), 12, 18, 0, 0);
    Expect(PresentationFit({12, 18, 1, 1}, true), 12, 18, 0, 0);
    auto safe = PresentationSafeArea(2622, 1206, 874, 402, 62, 0, 750, 381);
    Expect(safe, 186, 0, 2250, 1143);
    Expect(PresentationFit(safe, true), 295, 0, 2032, 1143);
    Expect(PresentationFit(safe, false), 549, 0, 1524, 1143);
    Expect(PresentationSafeArea(1001, 501, 500, 250, 1, 1, 498, 248), 3, 3, 995, 495);
    Expect(PresentationSafeArea(100, 50, 0, 0, 0, 0, 0, 0), 0, 0, 100, 50);
    Expect(PresentationSafeArea(100, 50, 100, 50, -1, 0, 100, 50), 0, 0, 100, 50);
    Expect(PresentationSafeArea(100, 50, 100, 50, 1, 0, 100, 50), 0, 0, 100, 50);
    // Odd sizes, resizing, rotation, and large dimensions remain centered and
    // bounded. Rounding loses less than one pixel on the fitted dimension.
    const uint32_t sizes[] = {0, 1, 2, 3, 4, 7, 9, 16, 101, 402, 874, 1206, 2622, UINT32_MAX};
    for (auto w : sizes) for (auto h : sizes) for (bool wide : {false, true}) {
        auto r = PresentationFit({0, 0, w, h}, wide);
        assert((uint64_t)r.x + r.w <= w && (uint64_t)r.y + r.h <= h);
        if (!r.w || !r.h) continue;
        assert(w - r.w - r.x >= r.x && w - r.w - r.x <= r.x + 1);
        assert(h - r.h - r.y >= r.y && h - r.h - r.y <= r.y + 1);
        int64_t error = (int64_t)r.w * (wide ? 9 : 3) - (int64_t)r.h * (wide ? 16 : 4);
        assert(error > -(wide ? 9 : 3) && error < (wide ? 16 : 4));
        assert(r.w == w || r.h == h);
    }
    puts("presentation geometry: PASS (aspect fit, safe-area pixels, rounding, resize and overflow)");
}
