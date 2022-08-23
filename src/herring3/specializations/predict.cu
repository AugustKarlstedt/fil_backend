#include <cstddef>
#include <herring3/constants.hpp>
#include <herring3/detail/postprocessor.hpp>
#include <herring3/detail/predict.cuh>
#include <kayak/cuda_stream.hpp>
#include <kayak/tree_layout.hpp>
namespace herring {

template void predict<
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
  std::optional<std::size_t>,
  int device,
  kayak::cuda_stream stream
);

}
