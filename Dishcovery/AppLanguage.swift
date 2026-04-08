//
//  AppLanguage.swift
//  Dishcovery
//
//  Created by Selim Hafez on 23/03/2026.
//


import Foundation

struct AppLanguage: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}

enum AppLanguages {
    static let all: [AppLanguage] = [
        AppLanguage(code: "af", name: "Afrikaans"),
        AppLanguage(code: "sq", name: "Albanian"),
        AppLanguage(code: "am", name: "Amharic"),
        AppLanguage(code: "ar", name: "Arabic"),
        AppLanguage(code: "hy", name: "Armenian"),
        AppLanguage(code: "az", name: "Azerbaijani"),
        AppLanguage(code: "eu", name: "Basque"),
        AppLanguage(code: "be", name: "Belarusian"),
        AppLanguage(code: "bn", name: "Bengali"),
        AppLanguage(code: "bs", name: "Bosnian"),
        AppLanguage(code: "bg", name: "Bulgarian"),
        AppLanguage(code: "ca", name: "Catalan"),
        AppLanguage(code: "ceb", name: "Cebuano"),
        AppLanguage(code: "zh-CN", name: "Chinese (Simplified)"),
        AppLanguage(code: "zh-TW", name: "Chinese (Traditional)"),
        AppLanguage(code: "co", name: "Corsican"),
        AppLanguage(code: "hr", name: "Croatian"),
        AppLanguage(code: "cs", name: "Czech"),
        AppLanguage(code: "da", name: "Danish"),
        AppLanguage(code: "nl", name: "Dutch"),
        AppLanguage(code: "en", name: "English"),
        AppLanguage(code: "eo", name: "Esperanto"),
        AppLanguage(code: "et", name: "Estonian"),
        AppLanguage(code: "fi", name: "Finnish"),
        AppLanguage(code: "fr", name: "French"),
        AppLanguage(code: "fy", name: "Frisian"),
        AppLanguage(code: "gl", name: "Galician"),
        AppLanguage(code: "ka", name: "Georgian"),
        AppLanguage(code: "de", name: "German"),
        AppLanguage(code: "el", name: "Greek"),
        AppLanguage(code: "gu", name: "Gujarati"),
        AppLanguage(code: "ht", name: "Haitian Creole"),
        AppLanguage(code: "ha", name: "Hausa"),
        AppLanguage(code: "haw", name: "Hawaiian"),
        AppLanguage(code: "he", name: "Hebrew"),
        AppLanguage(code: "hi", name: "Hindi"),
        AppLanguage(code: "hmn", name: "Hmong"),
        AppLanguage(code: "hu", name: "Hungarian"),
        AppLanguage(code: "is", name: "Icelandic"),
        AppLanguage(code: "ig", name: "Igbo"),
        AppLanguage(code: "id", name: "Indonesian"),
        AppLanguage(code: "ga", name: "Irish"),
        AppLanguage(code: "it", name: "Italian"),
        AppLanguage(code: "ja", name: "Japanese"),
        AppLanguage(code: "jv", name: "Javanese"),
        AppLanguage(code: "kn", name: "Kannada"),
        AppLanguage(code: "kk", name: "Kazakh"),
        AppLanguage(code: "km", name: "Khmer"),
        AppLanguage(code: "ko", name: "Korean"),
        AppLanguage(code: "ku", name: "Kurdish"),
        AppLanguage(code: "ky", name: "Kyrgyz"),
        AppLanguage(code: "lo", name: "Lao"),
        AppLanguage(code: "la", name: "Latin"),
        AppLanguage(code: "lv", name: "Latvian"),
        AppLanguage(code: "lt", name: "Lithuanian"),
        AppLanguage(code: "lb", name: "Luxembourgish"),
        AppLanguage(code: "mk", name: "Macedonian"),
        AppLanguage(code: "mg", name: "Malagasy"),
        AppLanguage(code: "ms", name: "Malay"),
        AppLanguage(code: "ml", name: "Malayalam"),
        AppLanguage(code: "mt", name: "Maltese"),
        AppLanguage(code: "mi", name: "Maori"),
        AppLanguage(code: "mr", name: "Marathi"),
        AppLanguage(code: "mn", name: "Mongolian"),
        AppLanguage(code: "my", name: "Myanmar (Burmese)"),
        AppLanguage(code: "ne", name: "Nepali"),
        AppLanguage(code: "no", name: "Norwegian"),
        AppLanguage(code: "ny", name: "Nyanja"),
        AppLanguage(code: "or", name: "Odia"),
        AppLanguage(code: "ps", name: "Pashto"),
        AppLanguage(code: "fa", name: "Persian"),
        AppLanguage(code: "pl", name: "Polish"),
        AppLanguage(code: "pt", name: "Portuguese"),
        AppLanguage(code: "pa", name: "Punjabi"),
        AppLanguage(code: "ro", name: "Romanian"),
        AppLanguage(code: "ru", name: "Russian"),
        AppLanguage(code: "sm", name: "Samoan"),
        AppLanguage(code: "gd", name: "Scots Gaelic"),
        AppLanguage(code: "sr", name: "Serbian"),
        AppLanguage(code: "st", name: "Sesotho"),
        AppLanguage(code: "sn", name: "Shona"),
        AppLanguage(code: "sd", name: "Sindhi"),
        AppLanguage(code: "si", name: "Sinhala"),
        AppLanguage(code: "sk", name: "Slovak"),
        AppLanguage(code: "sl", name: "Slovenian"),
        AppLanguage(code: "so", name: "Somali"),
        AppLanguage(code: "es", name: "Spanish"),
        AppLanguage(code: "su", name: "Sundanese"),
        AppLanguage(code: "sw", name: "Swahili"),
        AppLanguage(code: "sv", name: "Swedish"),
        AppLanguage(code: "tl", name: "Tagalog"),
        AppLanguage(code: "tg", name: "Tajik"),
        AppLanguage(code: "ta", name: "Tamil"),
        AppLanguage(code: "tt", name: "Tatar"),
        AppLanguage(code: "te", name: "Telugu"),
        AppLanguage(code: "th", name: "Thai"),
        AppLanguage(code: "tr", name: "Turkish"),
        AppLanguage(code: "tk", name: "Turkmen"),
        AppLanguage(code: "uk", name: "Ukrainian"),
        AppLanguage(code: "ur", name: "Urdu"),
        AppLanguage(code: "ug", name: "Uyghur"),
        AppLanguage(code: "uz", name: "Uzbek"),
        AppLanguage(code: "vi", name: "Vietnamese"),
        AppLanguage(code: "cy", name: "Welsh"),
        AppLanguage(code: "xh", name: "Xhosa"),
        AppLanguage(code: "yi", name: "Yiddish"),
        AppLanguage(code: "yo", name: "Yoruba"),
        AppLanguage(code: "zu", name: "Zulu")
    ].sorted { $0.name < $1.name }

    static func name(for code: String) -> String {
        all.first(where: { $0.code == code })?.name ?? code
    }
}