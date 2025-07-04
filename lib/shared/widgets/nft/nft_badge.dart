import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:komodo_wallet/app_config/app_config.dart';
import 'package:komodo_wallet/model/nft.dart';

class BlockchainBadge extends StatelessWidget {
  final NftBlockchains blockchain;
  const BlockchainBadge({
    super.key,
    required this.blockchain,
    this.width = 105,
    this.padding = const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
    this.iconSize = 15,
    this.iconColor = Colors.white,
    this.textStyle,
  });
  final double width;
  final EdgeInsets padding;
  final double iconSize;
  final Color iconColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final isSmallFont = blockchain.toString().length > 5;
    final style = textStyle ??
        TextStyle(
          fontSize: isSmallFont ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: iconColor,
        );
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: getColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
              '$assetsPath/blockchain_icons/svg/32px/${blockchain.toApiRequest().toLowerCase()}.svg',
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              height: iconSize,
              width: iconSize),
          const SizedBox(width: 2),
          Flexible(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  blockchain.toString(),
                  style: style,
                ),
              ),
              const SizedBox(width: 1),
            ],
          )),
        ],
      ),
    );
  }

  Color getColor() {
    switch (blockchain) {
      case NftBlockchains.eth:
        return const Color(0xFF3D77E9);
      case NftBlockchains.bsc:
        return const Color(0xFFE6BC41);
      case NftBlockchains.avalanche:
        return const Color(0xFFD54F49);
      case NftBlockchains.polygon:
        return const Color(0xFF7B49DD);
      case NftBlockchains.fantom:
        return const Color(0xFF3267F6);
    }
  }
}
