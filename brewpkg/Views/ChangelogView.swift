//
//  ChangelogView.swift
//  brewpkg
//
//  Created on 9/16/25.
//

import SwiftUI

struct ChangelogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var changelogContent: String = ""
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                Text("What's New in brewpkg")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            if isLoading {
                ProgressView("Loading changelog...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    ChangelogContentView(markdown: changelogContent)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            loadChangelog()
        }
    }

    private func loadChangelog() {
        isLoading = true

        // First try to load from bundle
        if let bundlePath = Bundle.main.path(forResource: "CHANGELOG", ofType: "md"),
           let content = try? String(contentsOfFile: bundlePath, encoding: .utf8) {
            changelogContent = content
            isLoading = false
            return
        }

        // Fallback: Load from project directory (for development)
        let projectPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CHANGELOG.md")

        if let content = try? String(contentsOf: projectPath, encoding: .utf8) {
            changelogContent = content
            isLoading = false
            return
        }

        // If neither works, show a default message
        changelogContent = """
        # Changelog

        Unable to load changelog file.

        Please check the [GitHub releases page](https://github.com/ugurkocde/brewpkg/releases) for the latest changes.
        """
        isLoading = false
    }
}

struct ChangelogContentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parseChangelog(markdown), id: \.id) { section in
                VStack(alignment: .leading, spacing: 8) {
                    if section.isHeader {
                        Text(section.content)
                            .font(section.headerLevel == 1 ? .largeTitle :
                                  section.headerLevel == 2 ? .title :
                                  section.headerLevel == 3 ? .title2 : .headline)
                            .fontWeight(section.headerLevel <= 2 ? .bold : .semibold)
                            .padding(.top, section.headerLevel == 2 ? 20 : 10)
                    } else if section.isList {
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(parseInlineMarkdown(section.content))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, CGFloat(section.indentLevel * 20))
                    } else if !section.content.isEmpty {
                        Text(parseInlineMarkdown(section.content))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var workingText = text
        var issueURLs: [String: String] = [:]

        // First, extract GitHub issue links and store them
        do {
            let linkRegex = try NSRegularExpression(pattern: "\\(\\[#(\\d+)\\]\\)\\(([^)]+)\\)", options: [])
            let matches = linkRegex.matches(in: workingText, range: NSRange(workingText.startIndex..., in: workingText))

            for match in matches {
                if match.numberOfRanges >= 3,
                   let issueRange = Range(match.range(at: 1), in: workingText),
                   let urlRange = Range(match.range(at: 2), in: workingText) {
                    let issueNumber = String(workingText[issueRange])
                    let url = String(workingText[urlRange])
                    issueURLs["#\(issueNumber)"] = url
                }
            }

            // Replace with just (#11) format
            workingText = workingText.replacingOccurrences(
                of: "\\(\\[#(\\d+)\\]\\([^)]+\\)\\)",
                with: "(#$1)",
                options: .regularExpression
            )
        } catch {
            // Continue with original text if regex fails
        }

        // Create the attributed string
        var result = AttributedString(workingText)

        // Apply bold formatting to **text** and remove the markers
        do {
            let boldRegex = try NSRegularExpression(pattern: "\\*\\*([^*]+)\\*\\*", options: [])

            // Keep replacing until no more bold markers exist
            while let match = boldRegex.firstMatch(in: String(result.characters), range: NSRange(String(result.characters).startIndex..., in: String(result.characters))) {
                guard match.numberOfRanges == 2,
                      let contentRange = Range(match.range(at: 1), in: String(result.characters)) else { break }

                let content = String(String(result.characters)[contentRange])
                var boldText = AttributedString(content)
                boldText.font = .body.bold()

                // Find the full match range in the AttributedString
                if let startIndex = result.index(result.startIndex, offsetByCharacters: match.range.location),
                   let endIndex = result.index(startIndex, offsetByCharacters: match.range.length) {
                    // Replace the entire **text** with just the bold text
                    result.replaceSubrange(startIndex..<endIndex, with: boldText)
                }
            }
        } catch {
            // If regex fails, just return the original attributed string
        }

        // Apply color and links to issue numbers (#11)
        do {
            let issueRegex = try NSRegularExpression(pattern: "\\(#(\\d+)\\)", options: [])
            let currentText = String(result.characters)
            let matches = issueRegex.matches(in: currentText, range: NSRange(currentText.startIndex..., in: currentText))

            for match in matches {
                if match.numberOfRanges >= 2,
                   let matchRange = Range(match.range(at: 0), in: currentText),
                   let issueNumberRange = Range(match.range(at: 1), in: currentText) {

                    let issueNumber = String(currentText[issueNumberRange])
                    let issueKey = "#\(issueNumber)"

                    if let startIndex = result.index(result.startIndex, offsetByCharacters: match.range.location),
                       let endIndex = result.index(startIndex, offsetByCharacters: match.range.length) {

                        result[startIndex..<endIndex].foregroundColor = .accentColor
                        result[startIndex..<endIndex].underlineStyle = .single

                        // Add the URL if we have it
                        if let urlString = issueURLs[issueKey],
                           let url = URL(string: urlString) {
                            result[startIndex..<endIndex].link = url
                        } else {
                            // Default to GitHub issues URL
                            if let url = URL(string: "https://github.com/ugurkocde/brewpkg/issues/\(issueNumber)") {
                                result[startIndex..<endIndex].link = url
                            }
                        }
                    }
                }
            }
        } catch {
            // If regex fails, continue
        }

        // Apply monospace font to `code` and remove backticks
        do {
            let codeRegex = try NSRegularExpression(pattern: "`([^`]+)`", options: [])

            // Keep replacing until no more code markers exist
            while let match = codeRegex.firstMatch(in: String(result.characters), range: NSRange(String(result.characters).startIndex..., in: String(result.characters))) {
                guard match.numberOfRanges == 2,
                      let contentRange = Range(match.range(at: 1), in: String(result.characters)) else { break }

                let content = String(String(result.characters)[contentRange])
                var codeText = AttributedString(content)
                codeText.font = .system(.body, design: .monospaced)
                codeText.backgroundColor = Color(NSColor.quaternaryLabelColor).opacity(0.2)

                // Find the full match range in the AttributedString
                if let startIndex = result.index(result.startIndex, offsetByCharacters: match.range.location),
                   let endIndex = result.index(startIndex, offsetByCharacters: match.range.length) {
                    // Replace the entire `text` with just the formatted text
                    result.replaceSubrange(startIndex..<endIndex, with: codeText)
                }
            }
        } catch {
            // If regex fails, continue
        }

        return result
    }

    private func parseChangelog(_ markdown: String) -> [ChangelogSection] {
        var sections: [ChangelogSection] = []
        let lines = markdown.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("#") {
                let headerLevel = trimmed.prefix(while: { $0 == "#" }).count
                let content = trimmed.dropFirst(headerLevel).trimmingCharacters(in: .whitespaces)
                sections.append(ChangelogSection(
                    content: content,
                    isHeader: true,
                    headerLevel: headerLevel
                ))
            } else if trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                let indentLevel = (line.count - trimmed.count) / 2
                sections.append(ChangelogSection(
                    content: content,
                    isList: true,
                    indentLevel: indentLevel
                ))
            } else if !trimmed.isEmpty {
                sections.append(ChangelogSection(content: trimmed))
            }
        }

        return sections
    }
}

struct ChangelogSection: Identifiable {
    let id = UUID()
    let content: String
    var isHeader: Bool = false
    var headerLevel: Int = 0
    var isList: Bool = false
    var indentLevel: Int = 0
}

#Preview {
    ChangelogView()
}

extension AttributedString {
    func index(_ i: Index, offsetByCharacters offset: Int) -> Index? {
        var currentIndex = i
        let direction = offset > 0 ? 1 : -1
        let count = abs(offset)

        for _ in 0..<count {
            if direction > 0 {
                guard currentIndex < self.endIndex else { return nil }
                currentIndex = self.index(afterCharacter: currentIndex)
            } else {
                guard currentIndex > self.startIndex else { return nil }
                currentIndex = self.index(beforeCharacter: currentIndex)
            }
        }
        return currentIndex
    }
}