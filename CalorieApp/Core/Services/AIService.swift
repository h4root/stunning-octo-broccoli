import Foundation

enum APIShape { case openAICompatible, anthropic, google }

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI, anthropic, google, groq, openRouter, deepSeek, mistral, xAI, perplexity, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAI:     return "OpenAI"
        case .anthropic:  return "Anthropic"
        case .google:     return "Google Gemini"
        case .groq:       return "Groq"
        case .openRouter: return "OpenRouter"
        case .deepSeek:   return "DeepSeek"
        case .mistral:    return "Mistral"
        case .xAI:        return "xAI (Grok)"
        case .perplexity: return "Perplexity (веб)"
        case .custom:     return "Свой / Bedrock-прокси"
        }
    }

    var shape: APIShape {
        switch self {
        case .anthropic: return .anthropic
        case .google:    return .google
        default:         return .openAICompatible
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openAI:     return "https://api.openai.com/v1"
        case .anthropic:  return "https://api.anthropic.com/v1"
        case .google:     return "https://generativelanguage.googleapis.com/v1beta"
        case .groq:       return "https://api.groq.com/openai/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .deepSeek:   return "https://api.deepseek.com/v1"
        case .mistral:    return "https://api.mistral.ai/v1"
        case .xAI:        return "https://api.x.ai/v1"
        case .perplexity: return "https://api.perplexity.ai"
        case .custom:     return ""
        }
    }

    var defaultModel: String { models.first ?? "" }

    /// Заготовки популярных моделей под провайдера.
    var models: [String] {
        switch self {
        case .openAI:     return ["gpt-4o-mini", "gpt-4o", "gpt-4.1-mini", "gpt-4.1", "o4-mini"]
        case .anthropic:  return ["claude-3-5-haiku-latest", "claude-3-5-sonnet-latest", "claude-3-7-sonnet-latest"]
        case .google:     return ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]
        case .groq:       return ["llama-3.3-70b-versatile", "llama-3.1-8b-instant", "mixtral-8x7b-32768"]
        case .openRouter: return ["openai/gpt-4o-mini", "anthropic/claude-3.5-haiku", "google/gemini-flash-1.5", "meta-llama/llama-3.3-70b-instruct"]
        case .deepSeek:   return ["deepseek-chat", "deepseek-reasoner"]
        case .mistral:    return ["mistral-small-latest", "mistral-large-latest", "open-mistral-nemo"]
        case .xAI:        return ["grok-2-latest", "grok-2-1212", "grok-beta"]
        case .perplexity: return ["sonar", "sonar-pro", "sonar-reasoning"]
        case .custom:     return []
        }
    }
}

enum AIConfig {
    static var provider: AIProvider {
        AIProvider(rawValue: UserDefaults.standard.string(forKey: "ai.provider") ?? "") ?? .openAI
    }
    static var apiKey: String { (UserDefaults.standard.string(forKey: "ai.apiKey") ?? "").trimmingCharacters(in: .whitespaces) }
    static var baseURL: String {
        let custom = (UserDefaults.standard.string(forKey: "ai.baseURL") ?? "").trimmingCharacters(in: .whitespaces)
        return custom.isEmpty ? provider.defaultBaseURL : custom
    }
    static var model: String {
        let custom = (UserDefaults.standard.string(forKey: "ai.model") ?? "").trimmingCharacters(in: .whitespaces)
        return custom.isEmpty ? provider.defaultModel : custom
    }
    static var isConfigured: Bool { !apiKey.isEmpty && !baseURL.isEmpty && !model.isEmpty }
}

enum AIError: LocalizedError {
    case notConfigured, badResponse(String), noData

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "ИИ не настроен. Укажите провайдера и ключ в Профиле."
        case .badResponse(let m): return m
        case .noData: return "ИИ не вернул данные о продукте."
        }
    }
}

struct AIService {
    static let shared = AIService()

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 40
        return URLSession(configuration: cfg)
    }()

    private let systemPrompt = """
    Ты — точный нутрициолог. Тебе дают название продукта (возможно бренд/штрихкод). \
    Найди или оцени пищевую ценность НА 100 г (для напитков и жидкостей — на 100 мл). \
    Если знаешь данные с упаковки или сайта производителя/ритейлера — используй их. \
    Ответь СТРОГО одним JSON-объектом без пояснений и markdown:
    {"name": "краткое название", "kcal": число, "protein": число, "fat": число, "carbs": число, "saturatedFat": число или null, "isLiquid": true/false}
    Поле saturatedFat — насыщенные жиры на 100 г; если не знаешь, поставь null.
    """

    func nutrition(for query: String) async throws -> FoodInfo {
        guard AIConfig.isConfigured else { throw AIError.notConfigured }
        let text = try await complete(user: query)
        guard let info = Self.parse(text, fallbackName: query) else { throw AIError.noData }
        return info
    }

    // MARK: - Отправка запроса по форме провайдера

    private func complete(user: String) async throws -> String {
        let base = AIConfig.baseURL
        let key = AIConfig.apiKey
        let model = AIConfig.model

        func makeURL(_ s: String) throws -> URL {
            guard let u = URL(string: s), u.scheme != nil else { throw AIError.badResponse("Некорректный URL запросов") }
            return u
        }

        switch AIConfig.provider.shape {
        case .openAICompatible:
            let url = try makeURL(base + "/chat/completions")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = [
                "model": model,
                "temperature": 0.2,
                "messages": [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": user]
                ]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let data = try await send(req)
            let decoded = try JSONDecoder().decode(OpenAIResp.self, from: data)
            return decoded.choices?.first?.message?.content ?? ""

        case .anthropic:
            let url = try makeURL(base + "/messages")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(key, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let body: [String: Any] = [
                "model": model,
                "max_tokens": 400,
                "system": systemPrompt,
                "messages": [["role": "user", "content": user]]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let data = try await send(req)
            let decoded = try JSONDecoder().decode(AnthropicResp.self, from: data)
            return decoded.content?.first?.text ?? ""

        case .google:
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let url = try makeURL("\(base)/models/\(model):generateContent?key=\(encodedKey)")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "system_instruction": ["parts": [["text": systemPrompt]]],
                "contents": [["parts": [["text": user]]]],
                "generationConfig": ["temperature": 0.2]
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            let data = try await send(req)
            let decoded = try JSONDecoder().decode(GoogleResp.self, from: data)
            return decoded.candidates?.first?.content?.parts?.first?.text ?? ""
        }
    }

    private func send(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.badResponse("HTTP \(http.statusCode): \(msg.prefix(200))")
        }
        return data
    }

    // MARK: - Разбор JSON из ответа модели

    static func parse(_ text: String, fallbackName: String) -> FoodInfo? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end else { return nil }
        let json = String(text[start...end])
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        func num(_ k: String) -> Double {
            if let d = obj[k] as? Double { return d }
            if let i = obj[k] as? Int { return Double(i) }
            if let s = obj[k] as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            return 0
        }
        func optNum(_ k: String) -> Double? {
            if obj[k] == nil || obj[k] is NSNull { return nil }
            if let d = obj[k] as? Double { return d }
            if let i = obj[k] as? Int { return Double(i) }
            if let s = obj[k] as? String { return Double(s.replacingOccurrences(of: ",", with: ".")) }
            return nil
        }
        let name = (obj["name"] as? String)?.trimmingCharacters(in: .whitespaces)
        let liquid = (obj["isLiquid"] as? Bool) ?? false
        let kcal = num("kcal")
        if kcal <= 0 && num("protein") <= 0 && num("carbs") <= 0 && num("fat") <= 0 { return nil }
        return FoodInfo(
            name: (name?.isEmpty == false ? name! : fallbackName),
            kcalPer100: kcal, proteinPer100: num("protein"), fatPer100: num("fat"), carbsPer100: num("carbs"),
            saturatedFatPer100: optNum("saturatedFat") ?? optNum("saturated_fat"),
            defaultGrams: liquid ? 250 : 100, isLiquid: liquid
        )
    }
}

// MARK: - DTO

private struct OpenAIResp: Decodable {
    struct Choice: Decodable { let message: Msg? }
    struct Msg: Decodable { let content: String? }
    let choices: [Choice]?
}
private struct AnthropicResp: Decodable {
    struct Block: Decodable { let text: String? }
    let content: [Block]?
}
private struct GoogleResp: Decodable {
    struct Candidate: Decodable { let content: Content? }
    struct Content: Decodable { let parts: [Part]? }
    struct Part: Decodable { let text: String? }
    let candidates: [Candidate]?
}
