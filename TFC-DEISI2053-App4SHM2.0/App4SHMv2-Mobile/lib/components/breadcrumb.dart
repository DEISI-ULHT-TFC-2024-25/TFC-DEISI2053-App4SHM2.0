import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

enum PageType {
  structures,
  reader,
  powerSpectrum,
  result,
  cableForce,
  none
}

class BreadCrumb extends StatefulWidget {
  final PageType pageType;
  final Function onNext;
  bool disabled;
  final String text;
  final String? structureType;

  BreadCrumb({Key? key, required this.pageType, required this.onNext, this.disabled = false, this.text = 'NEXT', this.structureType}) : super(key: key);

  @override
  State<BreadCrumb> createState() => _BreadCrumbState();
}

class _BreadCrumbState extends State<BreadCrumb> {

  static const IconData cableIcon = IconData(0xe11e, fontFamily: 'MaterialIcons');

  Widget getIconForPageType(PageType pageType, bool isSelected) {
    switch (pageType) {
      case PageType.structures:
        return isSelected ? const Icon(CupertinoIcons.square_list_fill) : const Icon(CupertinoIcons.square_list, color: CupertinoColors.systemGrey);
      case PageType.reader:
        return isSelected ? const Icon(CupertinoIcons.graph_square_fill) : const Icon(CupertinoIcons.graph_square, color: CupertinoColors.systemGrey);
      case PageType.powerSpectrum:
        return isSelected ? const Icon(CupertinoIcons.table_fill) : const Icon(CupertinoIcons.table, color: CupertinoColors.systemGrey);
      case PageType.result:
        return isSelected ? const Icon(CupertinoIcons.square_stack_3d_down_right_fill) : const Icon(CupertinoIcons.square_stack_3d_down_right, color: CupertinoColors.systemGrey);
      case PageType.cableForce:
        return widget.structureType == "cable"
            ? Icon(cableIcon, color: isSelected ? Colors.black : CupertinoColors.systemGrey)
            : Container();
      default:
        return const Icon(CupertinoIcons.question_square, color: CupertinoColors.destructiveRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: MediaQuery.of(context).size.width / 2,
            child: ScaleAnimation(child: widget),
          ),
          children: [
            Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Shimmer(
                      enabled: !widget.disabled,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.disabled ? Colors.grey.withOpacity(0.5) : Theme.of(context).colorScheme.primary,
                            textStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          onPressed: () {
                            if (!widget.disabled) {
                              setState(() {
                                widget.disabled = true;
                              });
                              widget.onNext(onFinished: () => setState(() => widget.disabled = false));
                            }
                          },
                          child: Text(widget.text),
                        ),
                      ),
                    ),
                  )
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                getIconForPageType(PageType.structures, widget.pageType == PageType.structures),
                const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey),
                getIconForPageType(PageType.reader, widget.pageType == PageType.reader),
                const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey),
                getIconForPageType(PageType.powerSpectrum, widget.pageType == PageType.powerSpectrum),
                if (widget.structureType == "cable") ...[
                  const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey),
                  getIconForPageType(PageType.cableForce, widget.pageType == PageType.cableForce),
                ],
                const Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey),
                getIconForPageType(PageType.result, widget.pageType == PageType.result),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
