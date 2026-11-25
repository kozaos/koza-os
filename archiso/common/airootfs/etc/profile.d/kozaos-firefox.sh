# Firefox's crashreporter uses SSE4.1 and dies with SIGILL on pre-Penryn Core 2 CPUs.
export MOZ_CRASHREPORTER_DISABLE=1
