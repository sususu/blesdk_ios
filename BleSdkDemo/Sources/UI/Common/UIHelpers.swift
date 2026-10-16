import UIKit

final class FlowStepCell: UITableViewCell {
    static let reuseId = "FlowStepCell"
    let apiLabel = UILabel()
    let descLabel = UILabel()
    let statusLabel = UILabel()
    let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        apiLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        apiLabel.numberOfLines = 0
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.numberOfLines = 0
        statusLabel.font = .boldSystemFont(ofSize: 12)
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [statusLabel, apiLabel, descLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ step: FlowStep) {
        apiLabel.text = step.api
        // Prefer description + optional platform note so iOS-only caveats are visible in the list.
        if let note = step.platformNote, !note.isEmpty {
            descLabel.text = "\(step.description)\n(\(note))"
        } else {
            descLabel.text = step.description
        }
        detailLabel.text = step.detail
        detailLabel.isHidden = (step.detail ?? "").isEmpty
        switch step.status {
        case .pending: statusLabel.text = L10n.tr("step_pending"); statusLabel.textColor = .secondaryLabel
        case .running: statusLabel.text = L10n.tr("step_running"); statusLabel.textColor = .systemBlue
        case .done: statusLabel.text = L10n.tr("step_done"); statusLabel.textColor = .systemGreen
        case .failed: statusLabel.text = L10n.tr("step_failed"); statusLabel.textColor = .systemRed
        case .skipped: statusLabel.text = L10n.tr("step_skipped"); statusLabel.textColor = .systemOrange
        }
    }
}

final class LogCell: UITableViewCell {
    static let reuseId = "LogCell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        textLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textLabel?.numberOfLines = 0
        textLabel?.lineBreakMode = .byWordWrapping
        selectionStyle = .none
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }
}

enum UIHelpers {
    static func makeButton(_ title: String, primary: Bool = false) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        b.titleLabel?.adjustsFontForContentSizeCategory = true
        b.titleLabel?.numberOfLines = 2
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.titleLabel?.minimumScaleFactor = 0.5
        b.titleLabel?.textAlignment = .center
        b.titleLabel?.lineBreakMode = .byTruncatingTail
        b.backgroundColor = primary ? UIColor.systemBlue : UIColor.tertiarySystemGroupedBackground
        b.setTitleColor(primary ? .white : .label, for: .normal)
        b.setTitleColor(.tertiaryLabel, for: .disabled)
        b.layer.cornerRadius = 10
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 56)).isActive = true
        return b
    }

    static func makeGrid(_ buttons: [UIButton]) -> UIStackView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        for start in stride(from: 0, to: buttons.count, by: 3) {
            let row = UIStackView(arrangedSubviews: Array(buttons[start..<min(start + 3, buttons.count)]))
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            while row.arrangedSubviews.count < 3 { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
        }
        return grid
    }

    static func makeCard(_ views: [UIView], title: String? = nil) -> UIStackView {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 8
        card.isLayoutMarginsRelativeArrangement = true
        card.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 12, bottom: 12, trailing: 12)
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        if let title {
            let heading = makeLabel(title, style: .headline)
            heading.accessibilityTraits.insert(.header)
            card.addArrangedSubview(heading)
        }
        views.forEach { card.addArrangedSubview($0) }
        return card
    }

    static func makeLogSection(_ textView: UITextView) -> UIStackView {
        textView.isHidden = true
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemGroupedBackground
        for constraint in textView.constraints where constraint.firstAttribute == .height {
            constraint.isActive = false
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
        let toggle = makeButton(L10n.tr("home_show_logs"))
        toggle.addAction(UIAction { [weak toggle, weak textView] _ in
            guard let textView else { return }
            textView.isHidden.toggle()
            toggle?.setTitle(L10n.tr(textView.isHidden ? "home_show_logs" : "home_hide_logs"), for: .normal)
        }, for: .touchUpInside)
        return makeCard([toggle, textView])
    }

    static func installScrollableContent(_ content: UIStackView, in view: UIView) {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .onDrag
        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    static func makeLabel(_ text: String = "", style: UIFont.TextStyle = .body) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .preferredFont(forTextStyle: style)
        l.adjustsFontForContentSizeCategory = true
        l.numberOfLines = 0
        return l
    }
}
