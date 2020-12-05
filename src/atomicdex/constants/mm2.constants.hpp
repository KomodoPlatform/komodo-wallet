#pragma once

#include <folly/Memory.h>
#include <folly/concurrency/ConcurrentHashMap.h>

namespace atomic_dex
{
    enum coin_type
    {
        QRC20,
        ERC20,
        UTXO,
        SmartChain
    };

    constexpr const char* g_qtum_infos_endpoint = "https://qtum.info/api/";

    using t_allocator     = folly::AlignedSysAllocator<std::uint8_t, folly::FixedAlign<bit_size<std::size_t>()>>;
    template <typename Key, typename Value>
    using t_concurrent_reg         = folly::ConcurrentHashMap<Key, Value, std::hash<Key>, std::equal_to<>, t_allocator>;
}