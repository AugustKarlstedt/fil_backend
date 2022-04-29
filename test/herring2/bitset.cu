/*
 * Copyright (c) 2022, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdint.h>
#include <gtest/gtest.h>
#include <herring2/bitset.hpp>
#include <herring2/buffer.hpp>

namespace herring {
__global__ void check_bitset_access(
    bool* out_small,
    bool* out_large,
    bitset<8, uint8_t> small_set,
    bitset<33, uint32_t> large_set) {

  for (auto i = uint32_t{}; i < small_set.size(); ++i) {
    out_small[i] = ((i % 2 == 0) == small_set.test(i));
  }
  for (auto i = uint32_t{}; i < large_set.size(); ++i) {
    out_large[i] = ((i % 2 == 0) == large_set.test(i));
  }

}
TEST(FilBackend, default_bitset_dev) {
  auto constexpr small_size = uint32_t{8};
  auto constexpr large_size = uint32_t{33};
  using small_set_t = bitset<small_size, uint8_t>;
  using large_set_t = bitset<large_size, uint32_t>;
  auto small_set = small_set_t{};
  auto large_set = large_set_t{};

  for (auto i = uint32_t{}; i < small_size; ++i) {
    if (i % 2 == 0) {
      small_set.set(i);
    }
  }
  for (auto i = uint32_t{}; i < large_size; ++i) {
    if (i % 2 == 0) {
      large_set.set(i);
    }
  }
  auto out_buf_small = buffer<bool>{small_set.size(), device_type::gpu};
  auto out_buf_large = buffer<bool>{large_set.size(), device_type::gpu};
  check_bitset_access<<<1,1>>>(out_buf_small.data(), out_buf_large.data(), small_set, large_set);
  auto out_buf_host_small = buffer<bool>{out_buf_small, device_type::cpu};
  auto out_buf_host_large = buffer<bool>{out_buf_large, device_type::cpu};
  cuda_check(cudaStreamSynchronize(0));
  for (auto i = uint32_t{}; i < out_buf_host_small.size(); ++i) {
    ASSERT_EQ(out_buf_host_small.data()[i], true);
  }
  for (auto i = uint32_t{}; i < out_buf_host_large.size(); ++i) {
    ASSERT_EQ(out_buf_host_large.data()[i], true);
  }
}

}
