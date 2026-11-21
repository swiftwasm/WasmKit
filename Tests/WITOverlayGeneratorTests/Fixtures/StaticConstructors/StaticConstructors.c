static unsigned int runs;

__attribute__((constructor)) static void count_run(void) {
    runs++;
}

unsigned int static_constructor_runs(void) {
    return runs;
}
