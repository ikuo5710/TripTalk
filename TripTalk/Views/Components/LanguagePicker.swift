//
//  LanguagePicker.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// 言語選択ピッカー
struct LanguagePicker: View {
    let title: String
    @Binding var selection: Language
    let excludedLanguage: Language
    let isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(Language.allCases.filter { $0 != excludedLanguage }) { language in
                    Button {
                        selection = language
                    } label: {
                        HStack {
                            Text(language.displayName)
                            if selection == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selection.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var input = Language.japanese
        @State var output = Language.english
        
        var body: some View {
            HStack {
                LanguagePicker(
                    title: "入力",
                    selection: $input,
                    excludedLanguage: output,
                    isEnabled: true
                )
                LanguagePicker(
                    title: "出力",
                    selection: $output,
                    excludedLanguage: input,
                    isEnabled: true
                )
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
