#pragma once

// Std Headers
#include <functional>

// Deps Headers
#include <entt/core/attribute.h>

// Project Headers
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"
#include "rpc.disable.hpp"
#include "rpc.recover.funds.hpp"
#include "rpc.hpp"
#include "rpc2.task.enable_z_coin.cancel.hpp"

namespace atomic_dex::mm2
{
    class ENTT_API mm2_client
    {
        pplx::cancellation_token_source m_token_source;

      public:
        mm2_client()  = default;
        ~mm2_client() = default;

        //! Create the client
        void stop();

        //! API
        pplx::task<web::http::http_response> async_rpc_batch_standalone(nlohmann::json batch_array);

        template <rpc Rpc>
        void process_rpc_async(const std::function<void(Rpc)>& on_rpc_processed);
        template <rpc Rpc>
        void process_rpc_async(typename Rpc::expected_request_type request, const std::function<void(Rpc)>& on_rpc_processed);

        //! Synced
        template <typename TRequest, typename TAnswer>
        TAnswer process_rpc(TRequest&& request, std::string rpc_command, bool is_v2 = false);

        template <typename RpcReturnType>
        RpcReturnType rpc_process_answer(const web::http::http_response& resp, const std::string& rpc_command);

        t_disable_coin_answer            rpc_disable_coin(t_disable_coin_request&& request);
        t_recover_funds_of_swap_answer   rpc_recover_funds(t_recover_funds_of_swap_request&& request);
        t_enable_z_coin_cancel_answer    rpc_enable_z_coin_cancel(t_enable_z_coin_cancel_request&& request);
    };
} // namespace atomic_dex