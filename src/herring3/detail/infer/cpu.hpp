#pragma once
#include <cstddef>
#include <optional>
#include <herring3/constants.hpp>
#include <herring3/detail/cpu_introspection.hpp>
#include <herring3/detail/forest.hpp>
#include <herring3/detail/infer_kernel/cpu.hpp>
#include <herring3/detail/postprocessor.hpp>
#include <kayak/cuda_stream.hpp>
#include <kayak/device_id.hpp>
#include <kayak/device_type.hpp>
#include <kayak/gpu_support.hpp>
namespace herring {
namespace detail {
namespace inference {

template<kayak::device_type D, typename forest_t, typename vector_output_t=std::nullptr_t>
std::enable_if_t<D==kayak::device_type::cpu || !kayak::GPU_ENABLED, void> infer(
  forest_t const& forest,
  postprocessor<typename forest_t::leaf_output_type, typename forest_t::io_type> const& postproc,
  typename forest_t::io_type* output,
  typename forest_t::io_type* input,
  std::size_t row_count,
  std::size_t col_count,
  std::size_t class_count,
  vector_output_t vector_output=nullptr,
  std::optional<std::size_t> specified_chunk_size=std::nullopt,
  kayak::device_id<D> device=kayak::device_id<D>{},
  kayak::cuda_stream=kayak::cuda_stream{}
) {
  if constexpr(D==kayak::device_type::gpu) {
    throw kayak::gpu_unsupported("Tried to use GPU inference in CPU-only build");
  } else {
    infer_kernel_cpu<false>(
      forest,
      postproc,
      output,
      input,
      row_count,
      col_count,
      class_count,
      specified_chunk_size.value_or(hardware_constructive_interference_size),
      hardware_constructive_interference_size,
      vector_output
    );
  }
}

extern template void infer<
  kayak::device_type::cpu,
  forest<
    preferred_tree_layout, float, uint32_t, uint16_t, uint16_t, float
  >
>(
  forest<
    preferred_tree_layout, float, uint32_t, uint16_t, uint16_t, float
  > const&,
  postprocessor<float, float> const&,
  float*,
  float*,
  std::size_t,
  std::size_t,
  std::size_t,
  float*,
  std::optional<std::size_t>,
  kayak::device_id<kayak::device_type::cpu>,
  kayak::cuda_stream stream
);

}
}
}
