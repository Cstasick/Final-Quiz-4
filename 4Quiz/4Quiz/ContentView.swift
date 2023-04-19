import UIKit
import SwiftUI

class ContentView: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Your view setup code
        var body: some View {
            NavigationView {
                VStack {
                    Image(systemName: "cloud.fill")
                    Spacer()
                    Text("weather data here")

                }
            }
            .navigationTitle("Weather App")
        }
    }
}

class ViewController: UIViewController {

    let imagePromptTextField = UITextField()
    let incompleteSentenceTextField = UITextField()
    let sentimentTextField = UITextField()
    let resultImageView = UIImageView()
    let resultLabel = UILabel()

    private let apiKey = "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"
    private let openAIAPIBaseURL = "https://api.openai.com/v1"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // Add this line
        setupUI()
    }


    func setupUI() {
        // Configure and add UIImageView
        resultImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultImageView)
        NSLayoutConstraint.activate([
            resultImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultImageView.topAnchor.constraint(equalTo: view.subviews.last!.bottomAnchor, constant: 40),

            resultImageView.widthAnchor.constraint(equalToConstant: 200),
            resultImageView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Configure and add UILabel
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        view.addSubview(resultLabel)
        NSLayoutConstraint.activate([
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            resultLabel.topAnchor.constraint(equalTo: resultImageView.bottomAnchor, constant: 20)
        ])
        // Add and configure text fields
        let textFields = [imagePromptTextField, incompleteSentenceTextField, sentimentTextField]
        for (index, textField) in textFields.enumerated() {
            textField.borderStyle = .roundedRect
            textField.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(textField)
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
                textField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: CGFloat(40 + 80 * index))
            ])
        }

        // Add and configure buttons
        let buttonTitles = ["Generate Image", "Complete Text", "Analyze Sentiment"]
        for (index, buttonTitle) in buttonTitles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.topAnchor.constraint(equalTo: textFields[index].bottomAnchor, constant: 16)
            ])

            switch index {
            case 0:
                button.addTarget(self, action: #selector(generateImageAction(_:)), for: .touchUpInside)
            case 1:
                button.addTarget(self, action: #selector(completeTextAction(_:)), for: .touchUpInside)
            case 2:
                button.addTarget(self, action: #selector(analyzeSentimentAction(_:)), for: .touchUpInside)
            default:
                break
            }
        }
    }

    @objc func generateImageAction(_ sender: UIButton) {
        guard let prompt = imagePromptTextField.text, !prompt.isEmpty else { return }
        generateImage(prompt: prompt) { result in
            switch result {
            case .success(let imageURL):
                if let url = URL(string: imageURL) {
                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url) {
                            DispatchQueue.main.async {
                                self.resultImageView.image = UIImage(data: data)
                            }
                        }
                    }
                }

            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    @objc func completeTextAction(_ sender: UIButton) {
        guard let incompleteSentence = incompleteSentenceTextField.text, !incompleteSentence.isEmpty else { return }
        completeText(prompt: incompleteSentence) { result in
            switch result {
            case .success(let completion):
                self.resultLabel.text = "\(incompleteSentence)\(completion)"
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    @objc func analyzeSentimentAction(_ sender: UIButton) {
        guard let sentence = sentimentTextField.text, !sentence.isEmpty else { return }
        analyzeSentiment(prompt: sentence) { result in
            switch result {
            case .success(let sentiment):
                print("Sentiment: \(sentiment)")
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - OpenAI API Functions
    private func generateImage(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        // ... (This part remains unchanged)
    }

    private func completeText(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(openAIAPIBaseURL)/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "text-davinci-002",
            "prompt": prompt,
            "max_tokens": 50
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            if let completions = jsonResponse["choices"] as? [[String: Any]], let completionText = completions.first?["text"] as? String {
                completion(.success(completionText))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Completion text not found"])))
            }
        }
        task.resume()
    }

    private func analyzeSentiment(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(openAIAPIBaseURL)/models/davinci-codex:2022-01-26/analyze_sentiment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "prompt": prompt,
            "num_results": 1
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            if let sentiment = jsonResponse["label"] as? String {
                completion(.success(sentiment))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sentiment not found"])))
            }
        }
        task.resume()
    }
    }
