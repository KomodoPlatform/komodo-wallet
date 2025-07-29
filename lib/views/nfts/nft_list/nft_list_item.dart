import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/model/nft.dart';
import 'package:web_dex/views/nfts/common/widgets/nft_image.dart';

class NftListItem extends StatefulWidget {
  const NftListItem({
    super.key,
    required this.nft,
    required this.onTap,
    required this.onSendTap,
  });
  final NftToken nft;
  final Function(String) onTap;
  final Function(String) onSendTap;

  @override
  State<NftListItem> createState() => _NftListItemState();
}

class _NftListItemState extends State<NftListItem> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    const heightSlideUpOnHover = 4.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          top: isHover ? -heightSlideUpOnHover : 0,
          bottom: isHover ? heightSlideUpOnHover : 0,
          left: 0,
          right: 0,
          child: MouseRegion(
            onEnter: (_) => setState(() => isHover = true),
            onExit: (_) => setState(() => isHover = false),
            child: Card(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Slidable(
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.5,
                  children: [
                    SlidableAction(
                      label: LocaleKeys.send.tr(),
                      onPressed: (_) => _onSendTap(),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).cardColor,
                      icon: Icons.send,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _onTap,
                  child: GridTile(
                    footer: _NftData(
                      nft: widget.nft,
                      onSendTap: _onSendTap,
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: isHover ? 1.05 : 1,
                            child: NftImage(imageUrl: widget.nft.imageUrl),
                          ),
                        ),

                        // Badge in top right corner to shown NFT amount
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _NftAmount(nft: widget.nft),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTap() {
    widget.onTap(widget.nft.uuid);
  }

  void _onSendTap() {
    widget.onSendTap(widget.nft.uuid);
  }
}

class _NftAmount extends StatelessWidget {
  const _NftAmount({required this.nft});
  final NftToken nft;

  @override
  Widget build(BuildContext context) {
    if (nft.contractType != NftContractType.erc1155) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          nft.amount,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _NftData extends StatelessWidget {
  const _NftData({
    required this.nft,
    required this.onSendTap,
  });
  final NftToken nft;
  final VoidCallback onSendTap;

  Text _tileText(String text) => Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      );

  @override
  Widget build(BuildContext context) {
    final mustShowSubtitle =
        nft.collectionName != null && nft.name != nft.collectionName;

    return GridTileBar(
      backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.9),
      title: _tileText(nft.name),
      subtitle: !mustShowSubtitle ? null : _tileText(nft.collectionName!),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
