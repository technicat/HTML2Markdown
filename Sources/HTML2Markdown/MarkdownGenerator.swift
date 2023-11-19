//
//  MarkdownGenerator.swift
//  HTML2Markdown
//
//  Created by Matthew Flint on 2021-12-08.
//

import Foundation
import SwiftSoup

public enum MarkdownGenerator {
    public struct Options: OptionSet {
        public let rawValue: Int

        /// Output a pretty bullet `•` instead of an asterisk, for unordered lists
        public static let unorderedListBullets = Options(rawValue: 1 << 0)
        /// Escape existing markdown syntax in order to prevent them being rendered
        public static let escapeMarkdown = Options(rawValue: 1 << 1)
        /// Try to respect Mastodon classes
        public static let mastodon = Options(rawValue: 1 << 2)
        /// Generate markdown that SwiftUI Text understands
        public static let swiftui = Options(rawValue: 1 << 3)
        /// boldface hashtags and remove links
        public static let boldTag = Options(rawValue: 1 << 4)
        /// boldface hashtags and remove links
        public static let boldMention = Options(rawValue: 1 << 5)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

/// markdown constants
public enum Markdown {
    static let empty = ""
    static let space = " "
    static let lbreak = "\n"
    static let pbreak = "\n\n"
    static let bold = "**"
    static let italic = "*"
    static let h1 = "#"
    static let h2 = "##"
    static let h3 = "###"
    static let h4 = "####"
    static let h5 = "#####"
    static let h6 = "######"
    static let pre = "\n```\n"
    static let code = "`"
}

extension Node {
    /// The parsed HTML formatted as Markddown
    ///
    /// - Parameter options: Options to customize the formatted text
    public func markdownFormatted(options: MarkdownGenerator.Options = []) -> String {
        var markdown = markdownFormattedRoot(options: options, context: [], childIndex: 0)

        // we only want a maximum of two consecutive newlines
        markdown = replace(regex: "[\n]{3,}",
                           with: Markdown.lbreak,
                           in: markdown)

        if options.contains(.mastodon) {
            markdown = markdown
                // Add space between hashtags and mentions that follow each other
                .replacingOccurrences(of: ")[", with: ") [")
        }

        if options.contains(.boldTag) || options.contains(.boldMention) {
            markdown = markdown
                // Add space between hashtags and mentions that follow each other
                .replacingOccurrences(of: "****", with: "** **")
        }

        return markdown
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func markdownFormattedRoot(
        options: MarkdownGenerator.Options,
        context: OutputContext,
        childIndex: Int,
        prefixPostfixBlock: ((String, String) -> Void)? = nil
    ) -> String {
        var result = Markdown.empty
        let childrenWithContent = self.getChildNodes().filter { $0.shouldRender() }

        for (index, child) in childrenWithContent.enumerated() {
            var context: OutputContext = []
            if childrenWithContent.count == 1 {
                context.insert(.isSingleChildInRoot)
            }
            if index == 0 {
                context.insert(.isFirstChild)
            }
            if index == childrenWithContent.count - 1 {
                context.insert(.isFinalChild)
            }
            result += child.markdownFormatted(options: options, context: context, childIndex: index)
        }

        return result
    }

    private func markdownFormatted(
        options: MarkdownGenerator.Options,
        context: OutputContext,
        childIndex: Int,
        prefixPostfixBlock: ((String, String) -> Void)? = nil
    ) -> String {
        var result = Markdown.empty
        let children = getChildNodes()

        switch self.nodeName() {
        case "pre":
            if context.contains(.isPre) {
                result += output(children, options: options, context: .isCode)
            } else {
                result += Markdown.pre + output(children, options: options, context: .isPre).trimmingCharacters(in: .whitespacesAndNewlines) + Markdown.pre
            }
        case "code":
            if context.contains(.isCode) {
                result += output(children, options: options, context: .isCode)
            } else if context.contains(.isPre) {
                result += output(children, options: options, context: .isCode)
            } else {
                result += Markdown.code + output(children, options: options, context: .isCode) + Markdown.code
            }
        case "span":
            if let classes = getAttributes()?.get(key: "class").split(separator: " ") {
                if options.contains(.mastodon) {
                    if classes.contains("invisible") {
                        break
                    }

                    result += output(children, options: options)

                    if classes.contains("ellipsis") {
                        result += "…"
                    }
                } else {
                    result += output(children, options: options)
                }
            } else {
                result += output(children, options: options)
            }
        case "p":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.lbreak
            }
        case "h1":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h1
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h1

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "h2":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h2
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h2

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "h3":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h3
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h3

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "h4":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h4
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h4

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "h5":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h5
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h5

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "h6":
            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFirstChild) {
                result += Markdown.lbreak
            }

            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h6
            result += output(children, options: options).trimmingCharacters(in: .whitespacesAndNewlines)
            result += options.contains(.swiftui) ? Markdown.bold : Markdown.h6

            if !context.contains(.isSingleChildInRoot),
               !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "br":
            if !context.contains(.isFinalChild) {
                result += Markdown.lbreak
            }
        // TODO: strip whitespace on the next line of text, immediately after this linebreak
        case "em", "i":
            var prefix = Markdown.empty
            var postfix = Markdown.empty

            let blockToPass: (String, String) -> Void = {
                prefix = $0
                postfix = $1
            }

            let text = output(children, options: options, prefixPostfixBlock: blockToPass)

            // I'd rather use _ here, but cmark-gfm has better behaviour with *
            result += "\(prefix)*\(text)*\(postfix)"
        case "strong", "b":
            var prefix = Markdown.empty
            var postfix = Markdown.empty

            let blockToPass: (String, String) -> Void = {
                prefix = $0
                postfix = $1
            }

            let text = output(children, options: options, prefixPostfixBlock: blockToPass)

            result += "\(prefix)**\(text)**\(postfix)"
        case "a":
            let content = output(children, options: options)
            if !context.contains(.isCode),
               (options.contains(.boldMention) && content.hasPrefix("@")) ||
                (options.contains(.boldTag) &&
                    content.hasPrefix("#")) {
                result += Markdown.bold
                result += content
                result += Markdown.bold
                break
            }
            if !context.contains(.isCode), let destination = getAttributes()?.get(key: "href"), !destination.isEmpty {
                result += "[\(content)](\(destination))"
            } else {
                result += content
            }
        case "ul":
            if !context.contains(.isFirstChild) {
                result += Markdown.pbreak
            }
            result += output(children, options: options, context: .isUnorderedList)

            if !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "ol":
            if !context.contains(.isFirstChild) {
                result += Markdown.pbreak
            }
            result += output(children, options: options, context: .isOrderedList)

            if !context.contains(.isFinalChild) {
                result += Markdown.pbreak
            }
        case "li":
            if context.contains(.isUnorderedList) {
                let bullet = options.contains(.unorderedListBullets) ? "•" : "*"
                result += "\(bullet) \(output(children, options: options))"
            }
            if context.contains(.isOrderedList) {
                result += "\(childIndex + 1). \(output(children, options: options))"
            }
            if !context.contains(.isFinalChild) {
                result += Markdown.lbreak
            }
        case "#text":
            // replace all whitespace with a single space, and escape *

            // Notes:
            // the first space here is an ideographic space, U+3000
            // second space is non-breaking space, U+00A0
            // third space is a regular space, U+0020
            let text = replace(regex: "[　  \t\n\r]{1,}", with: Markdown.space, in: description).stringByDecodingHTMLEntities
            if !text.isEmpty {
                if options.contains(.escapeMarkdown) {
                    result += text
                        .replacingOccurrences(of: "*", with: "\\*")
                        .replacingOccurrences(of: "[", with: "\\[")
                        .replacingOccurrences(of: "]", with: "\\]")
                        .replacingOccurrences(of: "`", with: "\\`")
                        .replacingOccurrences(of: "_", with: "\\_")
                } else {
                    result += text
                }
            }
        default:
            result += output(children, options: options)
        }

        return result
    }

    private func replace(regex pattern: String, with replacement: String, in string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return string
        }

        let range = NSRange(location: 0, length: string.utf16.count)

        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: replacement)
    }

    private func output(
        _ children: [Node],
        options: MarkdownGenerator.Options,
        context: OutputContext = [],
        prefixPostfixBlock: ((String, String) -> Void)? = nil
    ) -> String {
        var result = Markdown.empty
        let childrenWithContent = children.filter { $0.shouldRender() }

        for (index, child) in childrenWithContent.enumerated() {
            var context = context
            if index == 0 {
                context.insert(.isFirstChild)
            }
            if index == childrenWithContent.count - 1 {
                context.insert(.isFinalChild)
            }
            result += child.markdownFormatted(options: options, context: context, childIndex: index, prefixPostfixBlock: prefixPostfixBlock)
        }

        if let prefixPostfixBlock = prefixPostfixBlock {
            if result.hasPrefix(Markdown.space), result.hasSuffix(Markdown.space) {
                prefixPostfixBlock(Markdown.space,
                                   Markdown.space)
                result = result.trimmingCharacters(in: .whitespaces)
            } else if result.hasPrefix(Markdown.space) {
                prefixPostfixBlock(Markdown.space,
                                   Markdown.space)
                result = result.trimmingCharacters(in: .whitespaces)
            } else if result.hasSuffix(Markdown.space) {
                prefixPostfixBlock(Markdown.empty, Markdown.space)
                result = result.trimmingCharacters(in: .whitespaces)
            }
        }

        return result.stringByDecodingHTMLEntities
    }

    private func shouldRender() -> Bool {
        if let element = self as? TextNode {
            return !element.isBlank()
        }

        switch nodeName() {
        case "br":
            return true
        default:
            return !description.isEmpty
        }
    }
}
