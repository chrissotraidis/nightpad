extern "C" unsigned NightPadActionEngineThread(void *);
extern "C" unsigned NightPadDrivingEngineThread(void *);

int main() {
    return (&NightPadActionEngineThread == &NightPadDrivingEngineThread) ? 1 : 0;
}

