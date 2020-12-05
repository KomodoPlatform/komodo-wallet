/******************************************************************************
 * Copyright © 2013-2019 The Komodo Platform Developers.                      *
 *                                                                            *
 * See the AUTHORS, DEVELOPER-AGREEMENT and LICENSE files at                  *
 * the top-level directory of this distribution for the individual copyright  *
 * holder information and the developer policies on copyright and licensing.  *
 *                                                                            *
 * Unless otherwise agreed in a custom licensing agreement, no part of the    *
 * Komodo Platform software, including this file may be copied, modified,     *
 * propagated or distributed except according to the terms contained in the   *
 * LICENSE file                                                               *
 *                                                                            *
 * Removal or modification of this copyright notice is prohibited.            *
 *                                                                            *
 ******************************************************************************/

#pragma once

#include "system.manager.hpp"

namespace antara::gaming::ecs
{
    // LCOV_EXCL_START
    template <typename SystemToSwap, typename SystemB>
    bool
    system_manager::prioritize_system() noexcept
    {
        using namespace ranges;

        if (not has_systems<SystemToSwap, SystemB>())
            return false;
        if (SystemToSwap::get_system_type() != SystemB::get_system_type())
            return false;

        auto   sys_type          = SystemToSwap::get_system_type();
        auto&& sys_collection    = systems_[sys_type];
        auto   name              = SystemToSwap::get_class_name();
        auto   it_system_to_swap = find_if(sys_collection, [&name](auto&& sys) {
            return sys->get_name() == name;
        });
        name                     = SystemB::get_class_name();
        auto it_system_b         = find_if(sys_collection, [&name](auto&& sys) {
            return sys->get_name() == name;
        });

        if (it_system_to_swap != systems_[sys_type].end() && it_system_b != systems_[sys_type].end())
        {
            if (it_system_to_swap > it_system_b)
            {
                std::iter_swap(it_system_to_swap, it_system_b);
            }
            return true;
        }
        return false;
    }

    // LCOV_EXCL_STOP
    template <typename TSystem>
    const TSystem&
    system_manager::get_system() const noexcept
    {
        const auto ret = get_system_<TSystem>().or_else([this](const std::error_code& ec) {
            this->dispatcher_.trigger<gaming::event::fatal_error>(ec);
        });
        return (*ret).get();
    }

    template <typename TSystem>
    TSystem&
    system_manager::get_system() noexcept
    {
        auto ret = get_system_<TSystem>().or_else([this](const std::error_code& ec) {
            this->dispatcher_.trigger<gaming::event::fatal_error>(ec);
        });
        return (*ret).get();
    }

    template <typename... TSystems>
    std::tuple<std::add_lvalue_reference_t<TSystems>...>
    system_manager::get_systems() noexcept
    {
        return {get_system<TSystems>()...};
    }

    template <typename... TSystems>
    std::tuple<std::add_lvalue_reference_t<std::add_const_t<TSystems>>...>
    system_manager::get_systems() const noexcept
    {
        return {get_system<TSystems>()...};
    }

    template <typename TSystem, typename... TSystemArgs>
    TSystem&
    system_manager::create_system(TSystemArgs&&... args) noexcept
    {
        //LOG_SCOPE_FUNCTION(INFO);
        if (has_system<TSystem>())
        {
            return get_system<TSystem>();
        }
        auto creator = [this](auto&&... args_) {
            return std::make_unique<TSystem>(this->entity_registry_, std::forward<decltype(args_)>(args_)...);
        };

        system_ptr sys = creator(std::forward<TSystemArgs>(args)...);
        return static_cast<TSystem&>(add_system_(std::move(sys), TSystem::get_system_type()));
    }

    template <typename TSystem, typename... TSystemArgs>
    void
    system_manager::create_system_rt(TSystemArgs&&... args) noexcept
    {
        //LOG_SCOPE_FUNCTION(INFO);
        if (has_system<TSystem>())
        {
            return;
        }
        auto creator = [this](auto&&... args_) {
            return std::make_unique<TSystem>(this->entity_registry_, std::forward<decltype(args_)>(args_)...);
        };

        this->dispatcher_.trigger<event::add_base_system>(creator(std::forward<TSystemArgs>(args)...));
    }

    template <typename... TSystems, typename... TArgs>
    auto
    system_manager::load_systems(TArgs&&... args) noexcept
    {
        (create_system<TSystems>(std::forward<TArgs>(args)...), ...);
        return get_systems<TSystems...>();
    }

    template <typename TSystem>
    bool
    system_manager::has_system() const noexcept
    {
        constexpr const auto sys_type = TSystem::get_system_type();
        return ranges::any_of(systems_[sys_type], [](auto&& ptr) {
            return ptr->get_name() == TSystem::get_class_name();
        });
    }

    template <typename... TSystems>
    bool
    system_manager::has_systems() const noexcept
    {
        return (has_system<TSystems>() && ...);
    }

    template <typename TSystem>
    bool
    system_manager::mark_system() noexcept
    {
        if (has_system<TSystem>())
        {
            get_system<TSystem>().mark();
            need_to_sweep_systems_ = true;
            return true;
        }
        need_to_sweep_systems_ = false;
        return false;
    }

    template <typename... TSystems>
    bool
    system_manager::mark_systems() noexcept
    {
        return (mark_system<TSystems>() && ...);
    }

    template <typename TSystem>
    bool
    system_manager::enable_system() noexcept
    {
        if (has_system<TSystem>())
        {
            get_system<TSystem>().enable();
            return true;
        }
        return false;
    }

    template <typename... TSystems>
    bool
    system_manager::enable_systems() noexcept
    {
        return (enable_system<TSystems>() && ...);
    }

    template <typename TSystem>
    bool
    system_manager::disable_system() noexcept
    {
        if (has_system<TSystem>())
        {
            get_system<TSystem>().disable();
            return true;
        }
        return false;
    }

    template <typename... TSystems>
    bool
    system_manager::disable_systems() noexcept
    {
        return (disable_system<TSystems>() && ...);
    }

    template <typename TSystem>
    tl::expected<std::reference_wrapper<TSystem>, std::error_code>
    system_manager::get_system_() noexcept
    {
        if (not nb_systems(TSystem::get_system_type()))
        {
            return tl::make_unexpected(std::make_error_code(std::errc::result_out_of_range)); // LCOV_EXCL_LINE
        }

        constexpr const auto sys_type = TSystem::get_system_type();
        auto                 it       = ranges::find_if(systems_[sys_type], [](auto&& ptr) {
            return ptr->get_name() == TSystem::get_class_name();
        });

        if (it != systems_[sys_type].end())
        {
            auto& system = static_cast<TSystem&>(*(*it));
            return std::reference_wrapper<TSystem>(system);
        }
        return tl::make_unexpected(std::make_error_code(std::errc::result_out_of_range)); // LCOV_EXCL_LINE
    }

    template <typename TSystem>
    tl::expected<std::reference_wrapper<const TSystem>, std::error_code>
    system_manager::get_system_() const noexcept
    {
        if (not nb_systems(TSystem::get_system_type()))
        {
            return tl::make_unexpected(std::make_error_code(std::errc::result_out_of_range)); // LCOV_EXCL_LINE
        }

        constexpr const auto sys_type = TSystem::get_system_type();
        auto                 it       = ranges::find_if(systems_[sys_type], [](auto&& ptr) {
            return ptr->get_name() == TSystem::get_class_name();
        });
        if (it != systems_[sys_type].end())
        {
            const auto& system = static_cast<const TSystem&>(*(*it));
            return std::reference_wrapper<const TSystem>(system);
        }
        return tl::make_unexpected(std::make_error_code(std::errc::result_out_of_range)); // LCOV_EXCL_LINE
    }
} // namespace antara::gaming::ecs