import 'package:flutter/material.dart';

class CustomMarkdown extends StatelessWidget {
  final String data;
  final TextStyle? baseStyle;
  final Color? codeBackgroundColor;
  final Color? blockquoteColor;
  final List<Map<String, dynamic>>? regexStyles;

  const CustomMarkdown({
    Key? key,
    required this.data,
    this.baseStyle,
    this.codeBackgroundColor,
    this.blockquoteColor,
    this.regexStyles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultStyle = baseStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 16,
            ) ??
        const TextStyle(color: Colors.white, fontSize: 16);

    final lines = data.split('\n');
    final blocks = _parseBlocks(lines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks
          .map((block) => _renderBlock(context, block, defaultStyle))
          .toList(),
    );
  }

  List<_MarkdownBlock> _parseBlocks(List<String> lines) {
    final blocks = <_MarkdownBlock>[];
    int i = 0;

    RegExp orderedListRegex = RegExp('^(\d+)\.\s+(.*)');
    RegExp imageRegex = RegExp('^!\[(.*?)\]\((.*?)\)');

    while (i < lines.length) {
      final line = lines[i];
      final trimmedLine = line.trim();

      // --- 1. 处理代码块 ---
      if (trimmedLine.startsWith('```')) {
        List<String> codeContent = [];
        i++; // 跳过开头的 ```
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeContent.add(lines[i]);
          i++;
        }
        blocks.add(_MarkdownBlock(
          type: _BlockType.code,
          content: codeContent.join('\n'),
        ));
        i++; // 跳过结尾的 ```
        continue; // 处理下一块
      }

      // --- 2. 处理引用块 ---
      if (trimmedLine.startsWith('>')) {
        List<String> blockquoteLines = [];
        // 持续收集属于同一引用块的行
        while (i < lines.length) {
          final currentQuoteLine = lines[i];
          final trimmedCurrentQuoteLine = currentQuoteLine.trim();

          if (trimmedCurrentQuoteLine.startsWith('>')) {
            // 移除 '>' 和可能的后续空格
            blockquoteLines
                .add(currentQuoteLine.replaceFirst(RegExp(r'^\s*>\s?'), ''));
          } else if (trimmedCurrentQuoteLine.isEmpty) {
            // 如果是空行，也加入，保持格式
            blockquoteLines.add('');
          } else {
            // 如果不是以 '>' 开头且非空，则引用块结束
            break;
          }
          i++;
        }
        blocks.add(_MarkdownBlock(
          type: _BlockType.blockquote,
          content: blockquoteLines.join('\n'),
        ));
        continue; // 处理下一块 (i 已经在 break 或循环结束时指向了下一块的开始)
      }

      // --- 3. 处理其他块级元素 ---

      // 图片
      Match? imageMatch = imageRegex.firstMatch(trimmedLine);
      if (imageMatch != null) {
        blocks.add(_MarkdownBlock(
            type: _BlockType.image,
            content: imageMatch.group(1) ?? '', // Alt text
            url: imageMatch.group(2) // Image URL
            ));
      }
      // 标题 H1-H3
      else if (line.startsWith('# ')) {
        blocks.add(
            _MarkdownBlock(type: _BlockType.h1, content: line.substring(2)));
      } else if (line.startsWith('## ')) {
        blocks.add(
            _MarkdownBlock(type: _BlockType.h2, content: line.substring(3)));
      } else if (line.startsWith('### ')) {
        blocks.add(
            _MarkdownBlock(type: _BlockType.h3, content: line.substring(4)));
      }
      // 无序列表
      else if (trimmedLine.startsWith('- ') ||
          trimmedLine.startsWith('* ') ||
          trimmedLine.startsWith('+ ')) {
        blocks.add(_MarkdownBlock(
            type: _BlockType.bulletList, content: trimmedLine.substring(2)));
      }
      // 有序列表
      else {
        Match? orderedMatch = orderedListRegex.firstMatch(line);
        if (orderedMatch != null) {
          blocks.add(_MarkdownBlock(
              type: _BlockType.orderedList,
              content: orderedMatch.group(2)!,
              number: int.tryParse(orderedMatch.group(1)!) ?? 0));
        }
        // 水平分割线
        else if (trimmedLine == '---' || trimmedLine == '***') {
          blocks.add(_MarkdownBlock(type: _BlockType.divider, content: ''));
        }
        // 段落
        else if (trimmedLine.isNotEmpty) {
          blocks.add(_MarkdownBlock(type: _BlockType.paragraph, content: line));
        }
        // 空行
        else {
          blocks.add(_MarkdownBlock(type: _BlockType.empty, content: ''));
        }
      }

      i++; // 处理完当前行/块，移动到下一行
    }

    return blocks;
  }

  Widget _renderBlock(
      BuildContext context, _MarkdownBlock block, TextStyle defaultStyle) {
    switch (block.type) {
      case _BlockType.h1:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: CustomRichText(
            text: block.content,
            style: defaultStyle.copyWith(
              fontSize: defaultStyle.fontSize! * 1.5,
              fontWeight: FontWeight.bold,
            ),
            regexStyles: regexStyles,
          ),
        );

      case _BlockType.h2:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: CustomRichText(
            text: block.content,
            style: defaultStyle.copyWith(
              fontSize: defaultStyle.fontSize! * 1.3,
              fontWeight: FontWeight.bold,
            ),
            regexStyles: regexStyles,
          ),
        );

      case _BlockType.h3:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CustomRichText(
            text: block.content,
            style: defaultStyle.copyWith(
              fontSize: defaultStyle.fontSize! * 1.15,
              fontWeight: FontWeight.bold,
            ),
            regexStyles: regexStyles,
          ),
        );

      case _BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CustomRichText(
            text: block.content,
            style: defaultStyle,
            regexStyles: regexStyles,
          ),
        );

      case _BlockType.bulletList:
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: defaultStyle.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: CustomRichText(
                  text: block.content,
                  style: defaultStyle,
                  regexStyles: regexStyles,
                ),
              ),
            ],
          ),
        );

      case _BlockType.orderedList:
        return Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${block.number}.',
                  style: defaultStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: CustomRichText(
                  text: block.content,
                  style: defaultStyle,
                  regexStyles: regexStyles,
                ),
              ),
            ],
          ),
        );

      case _BlockType.blockquote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: blockquoteColor ?? Colors.grey.shade600,
                width: 4,
              ),
            ),
          ),
          child: CustomRichText(
            text: block.content,
            style: defaultStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: defaultStyle.color!.withOpacity(0.9),
            ),
            regexStyles: regexStyles,
          ),
        );

      case _BlockType.code:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: codeBackgroundColor ?? Colors.grey.shade800,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            block.content,
            style: defaultStyle.copyWith(
              fontFamily: 'monospace',
              color: Colors.green.shade300,
            ),
          ),
        );

      case _BlockType.image:
        // 简单的图片渲染：显示替代文本或URL
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '[图片: ${block.content.isNotEmpty ? block.content : block.url ?? '无效链接'}]',
            style: defaultStyle.copyWith(
                color: Colors.blue, fontStyle: FontStyle.italic),
          ),
        );

      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(
            color: defaultStyle.color!.withOpacity(0.5),
            thickness: 1,
          ),
        );

      case _BlockType.empty:
        return const SizedBox(height: 4);
    }
  }
}

// 自定义富文本组件，用于解析和渲染行内Markdown元素
class CustomRichText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final List<Map<String, dynamic>>? regexStyles;

  const CustomRichText({
    Key? key,
    required this.text,
    required this.style,
    this.regexStyles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = _parseInlineMarkdown(text, style);
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String text, TextStyle baseStyle) {
    List<InlineSpan> spans = [];
    List<_InlineMatch> matches = [];

    // 添加正则表达式样式匹配
    if (regexStyles != null) {
      for (final style in regexStyles!) {
        try {
          final regex = RegExp(style['regex'] as String);
          regex.allMatches(text).forEach((match) {
            final content = match.group(0);
            if (content != null) {
              matches.add(_InlineMatch(
                type: _InlineType.regex,
                start: match.start,
                end: match.end,
                text: content,
                fullMatch: content,
                style: TextStyle(
                  color: Color(style['color'] as int),
                  fontWeight: style['isBold'] as bool ? FontWeight.bold : null,
                  fontStyle:
                      style['isItalic'] as bool ? FontStyle.italic : null,
                ),
              ));
            }
          });
        } catch (e) {
          debugPrint('正则表达式解析错误: ${style['regex']} - $e');
        }
      }
    }

    // 现有的 Markdown 语法匹配
    final boldRegex = RegExp(r'\*\*(.*?)\*\*|__(.*?)__');
    final italicRegex = RegExp(r'\*(.*?)\*|_(.*?)_');
    final strikethroughRegex = RegExp(r'~~(.*?)~~');
    final codeRegex = RegExp(r'`(.*?)`');
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');

    // 查找粗体
    boldRegex.allMatches(text).forEach((match) {
      final content = match.group(1) ?? match.group(2);
      if (content != null) {
        matches.add(_InlineMatch(
          type: _InlineType.bold,
          start: match.start,
          end: match.end,
          text: content,
          fullMatch: match.group(0)!,
        ));
      }
    });

    // 查找斜体
    italicRegex.allMatches(text).forEach((match) {
      final content = match.group(1) ?? match.group(2);
      if (content != null) {
        bool isOverlappingWithBold = matches.any((m) =>
            m.type == _InlineType.bold &&
            (match.start >= m.start && match.end <= m.end));

        bool isPartOfBold = matches.any((m) =>
                m.type == _InlineType.bold &&
                ((match.start == m.start + 1 && match.end == m.end - 1) ||
                    (match.start == m.start && match.end == m.end - 2) ||
                    (match.start == m.start + 2 && match.end == m.end))
            // Add similar checks for __ _text_ __ etc. if needed
            );

        if (!isOverlappingWithBold && !isPartOfBold) {
          matches.add(_InlineMatch(
            type: _InlineType.italic,
            start: match.start,
            end: match.end,
            text: content,
            fullMatch: match.group(0)!,
          ));
        }
      }
    });

    // 新增：查找删除线
    strikethroughRegex.allMatches(text).forEach((match) {
      final content = match.group(1);
      if (content != null) {
        matches.add(_InlineMatch(
          type: _InlineType.strikethrough,
          start: match.start,
          end: match.end,
          text: content,
          fullMatch: match.group(0)!,
        ));
      }
    });

    // 查找行内代码
    codeRegex.allMatches(text).forEach((match) {
      final content = match.group(1);
      if (content != null) {
        matches.add(_InlineMatch(
          type: _InlineType.code,
          start: match.start,
          end: match.end,
          text: content,
          fullMatch: match.group(0)!,
        ));
      }
    });

    // 查找链接
    linkRegex.allMatches(text).forEach((match) {
      matches.add(_InlineMatch(
        type: _InlineType.link,
        start: match.start,
        end: match.end,
        text: match.group(1)!,
        url: match.group(2),
        fullMatch: match.group(0)!,
      ));
    });

    // 按照起始位置排序所有匹配项
    matches.sort((a, b) => a.start.compareTo(b.start));

    // 移除重叠的匹配项
    matches = _removeOverlappingMatches(matches);

    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
      return spans;
    }

    int currentIndex = 0;
    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      switch (match.type) {
        case _InlineType.regex:
          spans.add(TextSpan(
            text: match.text,
            style: baseStyle.merge(match.style),
          ));
          break;
        case _InlineType.bold:
          spans.addAll(_parseInlineMarkdown(
              match.text, baseStyle.copyWith(fontWeight: FontWeight.bold)));
          break;
        case _InlineType.italic:
          spans.addAll(_parseInlineMarkdown(
              match.text, baseStyle.copyWith(fontStyle: FontStyle.italic)));
          break;
        case _InlineType.strikethrough: // 新增：渲染删除线
          spans.addAll(_parseInlineMarkdown(match.text,
              baseStyle.copyWith(decoration: TextDecoration.lineThrough)));
          break;
        case _InlineType.code:
          spans.add(TextSpan(
            text: match.text,
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              backgroundColor: Colors.grey.shade800,
              color: Colors.green.shade300,
            ),
          ));
          break;
        case _InlineType.link:
          spans.add(TextSpan(
            text: match.text,
            style: baseStyle.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            // TODO: 添加点击事件来打开链接 match.url
          ));
          break;
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  List<_InlineMatch> _removeOverlappingMatches(List<_InlineMatch> matches) {
    if (matches.isEmpty) return matches;

    List<_InlineMatch> result = [matches[0]];
    for (int i = 1; i < matches.length; i++) {
      final current = matches[i];
      final previous = result.last;

      if (current.start >= previous.end) {
        result.add(current);
      }
    }
    return result;
  }
}

// 块级元素类型
enum _BlockType {
  h1,
  h2,
  h3,
  paragraph,
  bulletList,
  orderedList,
  blockquote,
  code,
  image,
  divider,
  empty,
}

// Markdown块
class _MarkdownBlock {
  final _BlockType type;
  final String content;
  final String? url; // 用于图片
  final int? number; // 用于有序列表

  _MarkdownBlock({
    required this.type,
    required this.content,
    this.url,
    this.number,
  });
}

// 行内元素类型
enum _InlineType {
  bold,
  italic,
  strikethrough,
  code,
  link,
  regex,
}

// 行内匹配
class _InlineMatch {
  final _InlineType type;
  final int start;
  final int end;
  final String text;
  final String? url;
  final String fullMatch;
  final TextStyle? style;

  _InlineMatch({
    required this.type,
    required this.start,
    required this.end,
    required this.text,
    this.url,
    required this.fullMatch,
    this.style,
  });
}
