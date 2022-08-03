#pragma once
#include<kayak/gpu_support.hpp>

namespace herring {
template <typename T, typename U>
HOST DEVICE auto ceildiv(T dividend, U divisor) {
  return (dividend + divisor - T{1}) / divisor;
}
}