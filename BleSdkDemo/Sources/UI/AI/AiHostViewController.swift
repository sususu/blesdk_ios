import UIKit

/// AI section hub — usage guide first, then AI DEMO (same button style as Home feature rows).
final class AiHostViewController: UIViewController {
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private var actionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.tr("ai_section")
        view.backgroundColor = .systemBackground

        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let hint = UIHelpers.makeLabel(L10n.tr("ai_host_hint"), style: .footnote)
        hint.textColor = .secondaryLabel
        content.addArrangedSubview(hint)

        let guide = UIHelpers.makeButton("")
        guide.addTarget(self, action: #selector(tapGuide), for: .touchUpInside)
        content.addArrangedSubview(guide)
        actionButtons.append(guide)

        let demo = UIHelpers.makeButton("")
        demo.addTarget(self, action: #selector(tapDemo), for: .touchUpInside)
        content.addArrangedSubview(demo)
        actionButtons.append(demo)

        applyLocalizedChrome()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLocalizedChrome()
    }

    private func applyLocalizedChrome() {
        let titles = [L10n.tr("ai_guide"), L10n.tr("ai_demo")]
        for (i, t) in titles.enumerated() where i < actionButtons.count {
            actionButtons[i].setTitle(t, for: .normal)
        }
    }

    @objc private func tapGuide() {
        navigationController?.pushViewController(AiGuideViewController(), animated: true)
    }

    @objc private func tapDemo() {
        navigationController?.pushViewController(AiDemoViewController(), animated: true)
    }
}
