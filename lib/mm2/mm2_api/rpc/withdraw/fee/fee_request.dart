class FeeRequest {
  FeeRequest({
    required this.type,
    this.amount,
    this.gasPrice,
    this.gasLimit,
    this.gas,
  });
  factory FeeRequest.fromJson(Map<String, dynamic> json) => FeeRequest(
        type: json['type'],
        amount: json['amount'],
        gasPrice: json['gas_price'],
        gasLimit: json['gas_limit'],
        gas: json['gas'],
      );

  /// type of transaction fee.
  /// Possible values:[UtxoFixed, UtxoPerKbyte, EthGas, CosmosGas, Qrc20Gas]
  String type;

  /// fee amount in coin units,
  /// used only when type is [UtxoFixed] (fixed amount not depending on tx size)
  /// or [UtxoPerKbyte] (amount per Kbyte).
  String? amount;

  /// used only when fee type is [EthGas], [QrcGas] or [CosmosGas].
  /// Sets the gas price in `gwei` units
  dynamic gasPrice;

  /// used only when fee type is [EthGas]. Sets the gas limit for transaction
  int? gas;

  /// used only when fee type is [CosmosGas] or [QrcGas].
  /// Sets the gas limit for transaction
  int? gasLimit;

  String getGasLimitAmount() => gas == null ? '' : gas.toString();
  dynamic getGasPrice() => gasPrice == null ? '' : gasPrice!;
  String getGasLimit() => gasLimit == null ? '' : gasLimit.toString();
  String getFeeAmount() => amount == null ? '' : amount!;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'amount': amount,
        'gas_price': gasPrice,
        'gas': gas,
        'gas_limit': gasLimit,
      };
}
