/* tslint:disable */
/* eslint-disable */
/**
 * Runs a MarketMaker2 instance.
 *
 * # Parameters
 *
 * * `conf` is a UTF-8 string JSON.
 * * `log_cb` is a JS function with the following signature:
 * ```typescript
 * function(level: number, line: string)
 * ```
 *
 * # Usage
 *
 * ```javascript
 * import init, {mm2_main, LogLevel, StartupResultCode} from "./path/to/mm2.js";
 *
 * const params = {
 *     conf: { "gui":"WASMTEST", mm2:1, "passphrase":"YOUR_PASSPHRASE_HERE", "rpc_password":"test123", "coins":[{"coin":"ETH","protocol":{"type":"ETH"}}] },
 *     log_level: LogLevel.Info,
 * };
 * let handle_log = function (_level, line) { console.log(line) };
 * try {
 *     mm2_main(params, handle_log);
 * } catch (e) {
 *     switch (e.code) {
 *         case StartupResultCode.AlreadyRunning:
 *             alert("MarketMaker2 already runs...");
 *             break;
 *         // handle other errors...
 *         default:
 *             alert(`Unexpected error: ${e}`);
 *             break;
 *     }
 * }
 * ```
 */
export function mm2_main(params: any, log_cb: Function): Promise<number>;
/**
 * Returns the MarketMaker2 instance status.
 */
export function mm2_main_status(): MainStatus;
/**
 * Invokes an RPC request.
 *
 * # Parameters
 *
 * * `payload` is a UTF-8 string JSON.
 *
 * # Usage
 *
 * ```javascript
 * import init, {mm2_rpc, Mm2RpcErr} from "./path/to/mm2.js";
 *
 * async function version () {
 *     try {
 *         const payload = {
 *             "userpass": "test123",
 *             "method": "version",
 *         };
 *         const response = await mm2_rpc(payload);
 *         return response.result;
 *     } catch (e) {
 *         switch (e) {
 *             case Mm2RpcErr.NotRunning:
 *                 alert("MarketMaker2 not running yet...");
 *                 break;
 *             // handle other errors...
 *             default:
 *                 alert(`Unexpected error: ${e}`);
 *                 break;
 *         }
 *     }
 * }
 * ```
 */
export function mm2_rpc(payload: any): Promise<any>;
/**
 * Get the MarketMaker2 version.
 *
 * # Usage
 *
 * The function can be used before mm2 runs.
 *
 * ```javascript
 * import init, {mm2_version} from "./path/to/mm2.js";
 *
 * function print_version () {
 *     const response = mm2_version();
 *     console.log(`version: ${response.result}, datetime: ${response.datetime}`);
 * }
 * ```
 */
export function mm2_version(): any;
/**
 * Stops the MarketMaker2 instance.
 *
 * # Usage
 *
 * ```javascript
 * import init, {mm2_stop} from "./path/to/mm2.js";
 *
 * async function stop () {
 *     try {
 *         await mm2_stop();
 *     } catch (e) {
 *         switch (e) {
 *             case Mm2RpcErr.NotRunning:
 *                 alert("MarketMaker2 not running yet...");
 *                 break;
 *             // handle other errors...
 *             default:
 *                 alert(`Unexpected error: ${e}`);
 *                 break;
 *         }
 *     }
 * }
 * ```
 */
export function mm2_stop(): Promise<void>;
/**
 * Handler for `console.log` invocations.
 *
 * If a test is currently running it takes the `args` array and stringifies
 * it and appends it to the current output of the test. Otherwise it passes
 * the arguments to the original `console.log` function, psased as
 * `original`.
 */
export function __wbgtest_console_log(args: Array<any>): void;
/**
 * Handler for `console.debug` invocations. See above.
 */
export function __wbgtest_console_debug(args: Array<any>): void;
/**
 * Handler for `console.info` invocations. See above.
 */
export function __wbgtest_console_info(args: Array<any>): void;
/**
 * Handler for `console.warn` invocations. See above.
 */
export function __wbgtest_console_warn(args: Array<any>): void;
/**
 * Handler for `console.error` invocations. See above.
 */
export function __wbgtest_console_error(args: Array<any>): void;
export function __wbgtest_cov_dump(): Uint8Array | undefined;
export enum LogLevel {
  /**
   * A level lower than all log levels.
   */
  Off = 0,
  /**
   * Corresponds to the `ERROR` log level.
   */
  Error = 1,
  /**
   * Corresponds to the `WARN` log level.
   */
  Warn = 2,
  /**
   * Corresponds to the `INFO` log level.
   */
  Info = 3,
  /**
   * Corresponds to the `DEBUG` log level.
   */
  Debug = 4,
  /**
   * Corresponds to the `TRACE` log level.
   */
  Trace = 5,
}
export enum MainStatus {
  /**
   * MM2 is not running yet.
   */
  NotRunning = 0,
  /**
   * MM2 is running, but no context yet.
   */
  NoContext = 1,
  /**
   * MM2 is running, but no RPC yet.
   */
  NoRpc = 2,
  /**
   * MM2's RPC is up.
   */
  RpcIsUp = 3,
}
/**
 * The errors can be thrown when using the `mm2_rpc` function incorrectly.
 */
export enum Mm2RpcErr {
  NotRunning = 1,
  InvalidPayload = 2,
  InternalError = 3,
}
export class RequestArguments {
  private constructor();
  free(): void;
  readonly method: string;
  readonly params: Array<any>;
}
export class StartupError {
  private constructor();
  free(): void;
  readonly code: number;
  readonly message: string;
}
/**
 * Runtime test harness support instantiated in JS.
 *
 * The node.js entry script instantiates a `Context` here which is used to
 * drive test execution.
 */
export class WasmBindgenTestContext {
  free(): void;
  /**
   * Creates a new context ready to run tests.
   *
   * A `Context` is the main structure through which test execution is
   * coordinated, and this will collect output and results for all executed
   * tests.
   */
  constructor();
  /**
   * Handle `--include-ignored` flag.
   */
  include_ignored(include_ignored: boolean): void;
  /**
   * Handle filter argument.
   */
  filtered_count(filtered: number): void;
  /**
   * Executes a list of tests, returning a promise representing their
   * eventual completion.
   *
   * This is the main entry point for executing tests. All the tests passed
   * in are the JS `Function` object that was plucked off the
   * `WebAssembly.Instance` exports list.
   *
   * The promise returned resolves to either `true` if all tests passed or
   * `false` if at least one test failed.
   */
  run(tests: any[]): Promise<any>;
}

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly __wbg_startuperror_free: (a: number, b: number) => void;
  readonly startuperror_code: (a: number) => number;
  readonly startuperror_message: (a: number, b: number) => void;
  readonly mm2_main: (a: number, b: number) => number;
  readonly mm2_main_status: () => number;
  readonly mm2_rpc: (a: number) => number;
  readonly mm2_version: () => number;
  readonly mm2_stop: () => number;
  readonly __wbgt__mm2_main::lp_ordermatch::my_orders_storage::tests::test_delete_my_maker_order: (a: number) => void;
  readonly __wbgt__mm2_main::lp_ordermatch::my_orders_storage::tests::test_delete_my_taker_order: (a: number) => void;
  readonly __wbgt__mm2_main::lp_ordermatch::my_orders_storage::tests::test_load_active_maker_taker_orders: (a: number) => void;
  readonly __wbgt__mm2_main::lp_ordermatch::my_orders_storage::tests::test_filtering_history: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::my_swaps_storage::wasm_tests::test_take_according_to_paging_opts: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::my_swaps_storage::wasm_tests::test_my_recent_swaps: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::saved_swap::tests::test_saved_swap_table: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::saved_swap::tests::test_get_current_migration: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::saved_swap::tests::test_migrate_swaps_data: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::swap_lock::tests::test_file_lock_should_create_file_and_record_timestamp_and_then_delete_on_drop: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::swap_lock::tests::test_file_lock_should_return_none_if_lock_acquired: (a: number) => void;
  readonly __wbgt__mm2_main::lp_swap::swap_lock::tests::test_file_lock_should_acquire_and_update_timestamp_if_ttl_expired: (a: number) => void;
  readonly __wbgt__mm2_main::lp_healthcheck::tests::test_encode_decode: (a: number) => void;
  readonly __wbgt__mm2_main::lp_healthcheck::tests::test_expired_message: (a: number) => void;
  readonly __wbgt__mm2_main::lp_healthcheck::tests::test_corrupted_messages: (a: number) => void;
  readonly __wbgt__mm2_main::lp_healthcheck::tests::test_valid_message: (a: number) => void;
  readonly __wbgt__mm2_main::lp_healthcheck::tests::test_peer_address: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_init_collection: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_upload_account: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_enable_account: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_set_name_desc_balance: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_activate_deactivate_coins: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_load_enabled_account_with_coins: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_load_accounts_with_enabled_flag: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_delete_account: (a: number) => void;
  readonly __wbgt__mm2_gui_storage::account::storage::account_storage_tests::wasm_tests::test_delete_account_clears_coins: (a: number) => void;
  readonly __wbgt__coins::eth::eth_wasm_tests::pass: (a: number) => void;
  readonly __wbgt__coins::eth::eth_wasm_tests::test_init_eth_coin: (a: number) => void;
  readonly __wbgt__coins::eth::eth_wasm_tests::wasm_test_sign_eth_tx: (a: number) => void;
  readonly __wbgt__coins::eth::eth_wasm_tests::wasm_test_sign_eth_tx_with_priority_fee: (a: number) => void;
  readonly __wbgt__coins::tendermint::rpc::tendermint_wasm_rpc::tests::test_get_abci_info: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::wasm::tx_history_storage_v1::tests::test_tx_history: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_init_collection: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_add_transactions: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_remove_transaction: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_get_transaction: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_update_transaction: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_contains_and_get_unconfirmed_transaction: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_has_transactions_with_hash: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_unique_tx_hashes_num: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_add_and_get_tx_from_cache: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_get_raw_tx_bytes_on_add_transactions: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_get_history_page_number: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_get_history_from_id: (a: number) => void;
  readonly __wbgt__coins::tx_history_storage::tx_history_v2_tests::wasm_tests::test_get_history_for_addresses: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_storage_init: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_add_block_headers: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_test_get_block_header: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_get_last_block_header_with_non_max_bits: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_get_last_block_height: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_block_header_storage::wasm_test::test_remove_headers_from_storage: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_wasm_tests::test_electrum_rpc_client: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_wasm_tests::test_electrum_display_balances: (a: number) => void;
  readonly __wbgt__coins::utxo::utxo_wasm_tests::test_hd_utxo_tx_history: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::blockdb::wasm_tests::test_insert_block_and_get_latest_block: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::blockdb::wasm_tests::test_rewind_to_height: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::blockdb::wasm_tests::test_transport: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::z_params::test_download_save_and_get_params: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::z_params::test_check_for_no_params: (a: number) => void;
  readonly __wbgt__coins::z_coin::tx_streaming_tests::wasm::test_zcoin_tx_streaming: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::z_locked_notes::locked_notes_test::test_sum_changes: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::z_locked_notes::locked_notes_test::test_load_all_notes: (a: number) => void;
  readonly __wbgt__coins::z_coin::storage::z_locked_notes::locked_notes_test::test_insert_and_remove_note: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_clear_all_history: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_clear_history: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_exclude_transfer_phishing_spam: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_update_transfer_phishing_by_domain: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_get_domains: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_exclude_transfer_spam: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_get_token_addresses: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_update_transfer_spam_by_token_address: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_get_update_transfer_meta: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_transfer_history_filters: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_transfer_history: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_last_transfer_block: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_add_get_transfers: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_clear_all_nft: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_clear_nft: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_exclude_nft_phishing_spam: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_update_nft_phishing_by_domain: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_get_animation_external_domains: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_exclude_nft_spam: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_update_nft_spam_by_token_address: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_refresh_metadata: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_nft_amount: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_remove_nft: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_nft_list: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_last_nft_block: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_add_get_nfts: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_camo: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_antispam_scan_endpoints: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_moralis_requests: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_check_for_spam_links: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_invalid_moralis_ipfs_link: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_get_domain_from_url: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_moralis_ipfs_bafy: (a: number) => void;
  readonly __wbgt__coins::nft::nft_tests::test_is_malicious: (a: number) => void;
  readonly __wbgt__coins::tendermint::tendermint_tx_history_v2::tests::test_get_value_from_event_attributes: (a: number) => void;
  readonly __wbgt__coins::hd_wallet::storage::tests::test_update_account: (a: number) => void;
  readonly __wbgt__coins::hd_wallet::storage::tests::test_delete_accounts: (a: number) => void;
  readonly __wbgt__coins::hd_wallet::storage::tests::test_unique_wallets: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::be_big_uint::tests::test_be_big_uint_ser_de: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::be_big_uint::tests::test_be_big_uint_debug_display: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::db_driver::cursor::multi_key_bound_cursor::tests::test_on_iteration_multiple_only_and_bound_values: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::db_driver::cursor::multi_key_bound_cursor::tests::test_on_iteration_multiple_bound_values: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::db_driver::cursor::multi_key_bound_cursor::tests::test_on_iteration_single_only_and_bound_values: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::db_driver::cursor::multi_key_bound_cursor::tests::test_on_iteration_error: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_be_big_uint_index: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_collect_single_key_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_collect_single_key_bound_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_collect_multi_key_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_collect_multi_key_bound_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_collect_multi_key_bound_cursor_big_int: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_iter_without_constraints: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_rev_iter_without_constraints: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_iter_single_key_bound_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_rev_iter_single_key_bound_cursor: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_where_condition: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_where_first_condition: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_where_first_but_reversed_condition: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_where_condition_with_limit: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_with_limit: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::indexed_cursor::tests::test_cursor_with_offset_and_limit: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_add_get_item: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_add_item_or_ignore: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_count: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_replace_item: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_delete_item: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_clear: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_upgrade_needed: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_open_twice: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_open_close_and_open: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_non_string_index: (a: number) => void;
  readonly __wbgt__mm2_db::indexed_db::tests::test_transaction_abort_on_error: (a: number) => void;
  readonly __wbgt__crypto::metamask_login::tests::test_hash_adex_login_request: (a: number) => void;
  readonly __wbgt__crypto::slip21::tests::test_encrypt_decrypt_with_slip21: (a: number) => void;
  readonly __wbgt__crypto::mnemonic::tests::test_mnemonic_with_last_byte_zero: (a: number) => void;
  readonly __wbgt__crypto::mnemonic::tests::test_encrypt_decrypt_non_bip39_mnemonic: (a: number) => void;
  readonly __wbgt__crypto::mnemonic::tests::test_encrypt_decrypt_mnemonic: (a: number) => void;
  readonly __wbgt__crypto::key_derivation::tests::test_slip_0021_key_derivation: (a: number) => void;
  readonly __wbg_requestarguments_free: (a: number, b: number) => void;
  readonly requestarguments_method: (a: number, b: number) => void;
  readonly requestarguments_params: (a: number) => number;
  readonly __wbgt__mm2_net::wasm::http::tests::fetch_get_test: (a: number) => void;
  readonly __wbgt__mm2_net::wasm::wasm_ws::tests::test_websocket: (a: number) => void;
  readonly __wbgt__mm2_net::wasm::wasm_ws::tests::test_websocket_unreachable_url: (a: number) => void;
  readonly rustsecp256k1_v0_4_1_context_create: (a: number) => number;
  readonly rustsecp256k1_v0_4_1_context_destroy: (a: number) => void;
  readonly rustsecp256k1_v0_4_1_default_illegal_callback_fn: (a: number, b: number) => void;
  readonly rustsecp256k1_v0_4_1_default_error_callback_fn: (a: number, b: number) => void;
  readonly __wbgt__mm2_event_stream::streamer::tests::test_spawn_erroring_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::streamer::tests::test_spawn_reactive_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::streamer::tests::test_spawn_periodic_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_remove_streamer_if_down: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_erroring_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_reactive_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_periodic_streamer: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_broadcast_all: (a: number) => void;
  readonly __wbgt__mm2_event_stream::manager::tests::test_add_remove_client: (a: number) => void;
  readonly __wbg_wasmbindgentestcontext_free: (a: number, b: number) => void;
  readonly wasmbindgentestcontext_new: () => number;
  readonly wasmbindgentestcontext_include_ignored: (a: number, b: number) => void;
  readonly wasmbindgentestcontext_filtered_count: (a: number, b: number) => void;
  readonly wasmbindgentestcontext_run: (a: number, b: number, c: number) => number;
  readonly __wbgtest_console_log: (a: number) => void;
  readonly __wbgtest_console_debug: (a: number) => void;
  readonly __wbgtest_console_info: (a: number) => void;
  readonly __wbgtest_console_warn: (a: number) => void;
  readonly __wbgtest_console_error: (a: number) => void;
  readonly __wbgtest_cov_dump: (a: number) => void;
  readonly __wbindgen_export_0: (a: number, b: number) => number;
  readonly __wbindgen_export_1: (a: number, b: number, c: number, d: number) => number;
  readonly __wbindgen_export_2: (a: number) => void;
  readonly __wbindgen_export_3: WebAssembly.Table;
  readonly __wbindgen_add_to_stack_pointer: (a: number) => number;
  readonly __wbindgen_export_4: (a: number, b: number, c: number) => void;
  readonly __wbindgen_export_5: (a: number, b: number, c: number) => void;
  readonly __wbindgen_export_6: (a: number, b: number) => void;
  readonly __wbindgen_export_7: (a: number, b: number) => void;
  readonly __wbindgen_export_8: (a: number, b: number, c: number) => void;
  readonly __wbindgen_export_9: (a: number, b: number) => void;
  readonly __wbindgen_export_10: (a: number, b: number, c: number, d: number, e: number) => void;
  readonly __wbindgen_export_11: (a: number, b: number, c: number, d: number) => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;
/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
*
* @returns {InitOutput}
*/
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
