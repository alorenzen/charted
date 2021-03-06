//
// Copyright 2014 Google Inc. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd
//

/// Provides a way to measure rendered text width for clipping
/// text on tooltips and ticks when they are too long.
library charted.core.text_metrics;

import "dart:html";
import "package:charted/core/text_metrics/segmentation.dart";

/// Utilities to measure text width.
class TextMetrics {
  static CanvasElement canvas;
  static CanvasRenderingContext2D context;
  static TextMetrics instance;

  static const MAX_STRING_LENGTH = 250;
  static final FONT_SIZE_REGEX = new RegExp("\s?([0-9]+)px\s?");

  final String fontStyle;
  int fontSize = 16;

  String currentFontStyle;

  factory TextMetrics({String fontStyle}) {
    if (canvas == null || context == null) {
      canvas = document.createElement('canvas');
      context = canvas.getContext('2d');
    }
    if (instance == null) {
      instance = new TextMetrics._internal(fontStyle);
    }
    return instance;
  }
  TextMetrics._internal(this.fontStyle) {
    Match match = FONT_SIZE_REGEX.firstMatch(fontStyle);
    fontSize = int.parse(match.group(1));
  }

  void setFontStyle(String fontStyle) {
    if (fontStyle == null) {
      fontStyle = this.fontStyle;
    }
    if (currentFontStyle != fontStyle) {
      context.font = fontStyle;
      currentFontStyle = fontStyle;
    }
  }

  /// Measure width of [text] in pixels.
  /// Optionally, uses [fontStyle] instead of using the default style
  double getTextWidth(String text, {String fontStyle}) {
    assert(text.length <= MAX_STRING_LENGTH);
    setFontStyle(fontStyle);
    return context.measureText(text).width;
  }

  /// Gets length of the longest string in the given [strings].
  /// Optionally, uses [fontStyle] instead of using the default style.
  double getLongestTextWidth(Iterable<String> strings, {String fontStyle}) {
    setFontStyle(fontStyle);
    double maxWidth = 0.0;
    for (int i = 0; i < strings.length; ++i) {
      assert(strings.elementAt(i).length <= MAX_STRING_LENGTH);
      double width = context.measureText(strings.elementAt(i)).width;
      if (width > maxWidth) {
        maxWidth = width;
      }
    }

    return maxWidth;
  }

  /// Truncates given [text] to fit in [width]. Adds an ellipsis to the
  /// returned string, if it needed to be truncated.
  /// Optionally, uses [fontStyle] instead of using the default style.
  String ellipsizeText(String text, double width, {String fontStyle}) {
    assert(text.length <= MAX_STRING_LENGTH);
    setFontStyle(fontStyle);
    double computedWidth = context.measureText(text).width;
    if (computedWidth > width) {
      var indices = graphemeBreakIndices(text);
      var position = 0,
          lo = 0, hi = indices.length, mid,
          ellipsis = context.measureText('…').width;
      width = width - ellipsis;
      while (lo < hi) {
        mid = (lo + hi) ~/ 2;
        position = indices[mid];
        if (context.measureText(text.substring(0, position)).width > width) {
          hi = mid - 1;
        } else {
          lo = mid + 1;
        }
      }
      text = text.substring(0, indices[mid]) + '…';
    }
    return text;
  }

  /// Truncates text in the given [element], which is either a [SvgTextElement]
  /// or a [SvgTspanElement] to fit in [width]. Appends an ellipsis to the text
  /// if it had to be truncated.
  /// Calling this method may force a layout on the document. For better
  /// performance, use [TextMetrics.ellipsizeText].
  static ellipsizeTextElement() {
  }
}
