#include "CWasmKitWASIThreads.h"

#include <errno.h>
#include <pthread.h>
#include <stdlib.h>

struct wasmkit_wasi_threads_context {
  wasmkit_wasi_threads_entry entry;
  void *context;
};

struct wasmkit_wasi_threads_event {
  pthread_mutex_t mutex;
  pthread_cond_t condition;
  int signaled;
};

static void *wasmkit_wasi_threads_trampoline(void *opaque) {
  struct wasmkit_wasi_threads_context *context = opaque;
  context->entry(context->context);
  free(context);
  return NULL;
}

int wasmkit_wasi_threads_start(
    wasmkit_wasi_threads_entry entry,
    void *context,
    size_t stack_size
) {
  pthread_attr_t attributes;
  int error = pthread_attr_init(&attributes);
  if (error != 0) return error;

  error = pthread_attr_setdetachstate(&attributes, PTHREAD_CREATE_DETACHED);
  if (error == 0 && stack_size != 0) {
    error = pthread_attr_setstacksize(&attributes, stack_size);
  }
  if (error == 0) {
    pthread_t thread;
    struct wasmkit_wasi_threads_context *worker = malloc(sizeof(*worker));
    if (worker == NULL) {
      error = ENOMEM; // pthread APIs return error codes rather than errno.
    } else {
      worker->entry = entry;
      worker->context = context;
      error = pthread_create(&thread, &attributes, wasmkit_wasi_threads_trampoline, worker);
      if (error != 0) free(worker);
    }
  }
  // A successfully initialized attribute object is always destroyed before
  // returning. Its destruction cannot turn an already-created worker into a
  // failed creation, because Swift has transferred ownership of its context.
  (void)pthread_attr_destroy(&attributes);
  return error;
}

wasmkit_wasi_threads_event *wasmkit_wasi_threads_event_create(void) {
  struct wasmkit_wasi_threads_event *event = malloc(sizeof(*event));
  if (event == NULL) return NULL;
  if (pthread_mutex_init(&event->mutex, NULL) != 0) {
    free(event);
    return NULL;
  }
  if (pthread_cond_init(&event->condition, NULL) != 0) {
    (void)pthread_mutex_destroy(&event->mutex);
    free(event);
    return NULL;
  }
  event->signaled = 0;
  return event;
}

void wasmkit_wasi_threads_event_destroy(wasmkit_wasi_threads_event *event) {
  (void)pthread_cond_destroy(&event->condition);
  (void)pthread_mutex_destroy(&event->mutex);
  free(event);
}

void wasmkit_wasi_threads_event_wait(wasmkit_wasi_threads_event *event) {
  (void)pthread_mutex_lock(&event->mutex);
  while (!event->signaled) {
    (void)pthread_cond_wait(&event->condition, &event->mutex);
  }
  (void)pthread_mutex_unlock(&event->mutex);
}

void wasmkit_wasi_threads_event_signal(wasmkit_wasi_threads_event *event) {
  (void)pthread_mutex_lock(&event->mutex);
  event->signaled = 1;
  (void)pthread_cond_signal(&event->condition);
  (void)pthread_mutex_unlock(&event->mutex);
}
