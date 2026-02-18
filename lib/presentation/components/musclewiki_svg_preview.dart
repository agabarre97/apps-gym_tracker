import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MuscleWikiSvgPreview extends StatelessWidget {
  const MuscleWikiSvgPreview({
    super.key,
    required this.musclesInvolved,
    this.width = 88,
    this.height = 108,
  });

  final List<String> musclesInvolved;
  final double width;
  final double height;

  static Future<_SvgTemplates>? _templatesFuture;

  static Future<_SvgTemplates> _loadTemplates() {
    return _templatesFuture ??= () async {
      final front = await rootBundle
          .loadString('assets/data/musclewiki/svg_templates/front.svg');
      final back = await rootBundle
          .loadString('assets/data/musclewiki/svg_templates/back.svg');
      return _SvgTemplates(front: front, back: back);
    }();
  }

  @override
  Widget build(BuildContext context) {
    final highlightedIds = musclesInvolved.toSet();
    return FutureBuilder<_SvgTemplates>(
      future: _loadTemplates(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: Icon(Icons.accessibility_new, size: 18)),
          );
        }

        final templates = snapshot.data!;
        final frontSvg = _applyHighlight(templates.front, highlightedIds);
        final backSvg = _applyHighlight(templates.back, highlightedIds);

        return SizedBox(
          width: width,
          height: height,
          child: Row(
            children: [
              Expanded(
                child: SvgPicture.string(
                  frontSvg,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SvgPicture.string(
                  backSvg,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SvgTemplates {
  const _SvgTemplates({
    required this.front,
    required this.back,
  });

  final String front;
  final String back;
}

String _applyHighlight(String templateSvg, Set<String> highlightedIds) {
  // flutter_svg does NOT apply <style> CSS rules nor resolve the `color`
  // attribute inheritance for fill="currentColor". Inline fill colors directly.
  const highlightColor = '#448AFF';
  const neutralColor = '#9CA3AF';

  // 1. Strip embedded <style> blocks.
  var result = templateSvg.replaceAll(
    RegExp(r'<style\b[^>]*>.*?</style>', dotAll: true),
    '',
  );

  // 2. Replace every fill="currentColor" with neutral gray globally.
  //    Covers all bodymap groups and hidden joint elements.
  result = result.replaceAll('fill="currentColor"', 'fill="$neutralColor"');

  // 3. For each highlighted muscle id, locate its <g bodymap> block and
  //    switch the fills inside it to the highlight color.
  for (final muscleId in highlightedIds) {
    result =
        _recolorMuscleBlock(result, muscleId, highlightColor, neutralColor);
  }

  return result;
}

/// Finds the `<g id="[muscleId]" class="...bodymap...">` block and replaces
/// every [currentNeutral] fill inside it with [targetColor].
///
/// Muscle-group `<g>` elements contain only `<path>` children (no nested `<g>`),
/// so the first `</g>` after the opening tag is always the correct boundary.
String _recolorMuscleBlock(
  String svg,
  String muscleId,
  String targetColor,
  String currentNeutral,
) {
  final idAttr = 'id="$muscleId"';
  final idPos = svg.indexOf(idAttr);
  if (idPos == -1) return svg;

  // Walk back to the start of the <g opening tag.
  final gStart = svg.lastIndexOf('<g', idPos);
  if (gStart == -1) return svg;

  // Find the closing > of the opening tag.
  final openTagEnd = svg.indexOf('>', gStart);
  if (openTagEnd == -1) return svg;

  // Only process bodymap muscle groups, not structural/joint elements.
  if (!svg.substring(gStart, openTagEnd + 1).contains('bodymap')) return svg;

  // Find the first </g> after the opening tag.
  final closeTagPos = svg.indexOf('</g>', openTagEnd + 1);
  if (closeTagPos == -1) return svg;

  final inner = svg.substring(openTagEnd + 1, closeTagPos);
  final replaced = inner.replaceAll(
    'fill="$currentNeutral"',
    'fill="$targetColor"',
  );

  return svg.substring(0, openTagEnd + 1) +
      replaced +
      svg.substring(closeTagPos);
}
