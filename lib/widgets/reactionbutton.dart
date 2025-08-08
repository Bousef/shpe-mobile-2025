import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


enum Reaction { like, favorite, clapp, cool, rocket, computer, loco, none }

class ReactionButton extends StatefulWidget {
  const ReactionButton({super.key});

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  Reaction _reaction = Reaction.none;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  static const double _mainButtonSize = 38.0;

  final List<ReactionElements> reactions = [
    ReactionElements(
      Reaction.like, Icon(Icons.thumb_up, size: 22, color: Color(0xFFF2AC02)),),
    ReactionElements(
      Reaction.favorite, Icon(Icons.favorite, size: 22, color:Color(0xFFFF7C72)),),
    ReactionElements(
      Reaction.clapp, Text("👏", style: TextStyle(fontSize: 20)),),
    ReactionElements(
      Reaction.cool, Text("😎", style: TextStyle(fontSize: 20)),),     
    ReactionElements(
      Reaction.rocket, Text("🚀", style: TextStyle(fontSize: 20)),),
    ReactionElements(
      Reaction.computer,Text("👩‍💻", style: TextStyle(fontSize: 20)),),
    ReactionElements(
      Reaction.loco, Text("🤪", style: TextStyle(fontSize: 20)),
        ),
  ];

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showReactionOverlay() {
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, -50),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 40,
                width: 300, 
                margin: const EdgeInsets.only(left: 15),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: reactions.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 250),
                      child: SlideAnimation(
                        verticalOffset: 15 + index * 5,
                        child: FadeInAnimation(
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _reaction = reactions[index].reaction;
                              });
                              _removeOverlay();
                            },
                            icon: reactions[index].widget,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _mainButtonSize, 
      height: _mainButtonSize, 
      child: CompositedTransformTarget(
        link: _layerLink,
        child: InkWell(
          onTap: () {
            setState(() {
              _reaction = _reaction == Reaction.none ? Reaction.like : Reaction.none;
            });
            _removeOverlay();
          },
          onLongPress: () {
            _showReactionOverlay();
          },
          child: getReactionIcon(_reaction),
        ),
      ),
    );
  }

  Widget getReactionIcon(Reaction r) {
    switch (r) {
      case Reaction.like:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: const BoxDecoration(
            color: Color(0xFFFBE6B3),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.thumb_up, size: 22, color: Color(0xFFF2AC02)),
          ),
        );
      case Reaction.favorite:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: const BoxDecoration(
            color: Color(0xFFFF7C72),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.favorite, size: 22, color: Color(0xFFFFCDD2)),
          ),
        );
      case Reaction.clapp:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: BoxDecoration(
            color: Color(0xFFF8D794),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("👏", style: TextStyle(fontSize: 20)),
          ),
        );
      case Reaction.cool:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: const BoxDecoration(
            color: Color(0xFFF8D794),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("😎", style: TextStyle(fontSize: 20)),
          ),
        );

      case Reaction.rocket:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: BoxDecoration(
            color: Color(0xFF78898F),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("🚀", style: TextStyle(fontSize: 20)),
          ),
        );

      case Reaction.computer:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: BoxDecoration(
            color: Color(0xFF78898F),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("👩‍💻", style: TextStyle(fontSize: 20)),
          ),
        );
      case Reaction.loco:
        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          decoration: BoxDecoration(
            color: Color(0xFFF8D794),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text("🤪", style: TextStyle(fontSize: 20)),
          ),
        );

      default:

        return Container(
          width: _mainButtonSize,
          height: _mainButtonSize,
          
          child: const Center(
            child: Icon(Icons.thumb_up, size: 22, color: Colors.white), // Default thumb-up icon
          ),
        );
    }
  }
}

class ReactionElements {
  final Reaction reaction;
  final Widget widget;
  ReactionElements(this.reaction, this.widget);
}