#pragma once
#include <kayak/tree_layout.hpp>

namespace herring {
namespace detail {
auto constexpr static const preferred_tree_layout = kayak::tree_layout::depth_first;
}
}