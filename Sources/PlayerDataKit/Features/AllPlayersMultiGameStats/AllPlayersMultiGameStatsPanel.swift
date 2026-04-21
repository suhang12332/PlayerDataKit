import Combine
import SwiftUI

/// 启动器「全部玩家 × 全部游戏」统计：状态与加载逻辑（供 `CommonSheetView` 的 header / body 拆分使用）。
@MainActor
public final class AllPlayersMultiGameStatsController: ObservableObject {
    public enum ContentState: Equatable {
        case loading
        case loaded
        case emptyPlayers
        case emptySaves
        case failed(String)
    }

    @Published private(set) var reports: [MultiGamePlayerReport] = []
    @Published private(set) var contentState: ContentState = .loading

    @Published var playerPickerSelection: String = MultiGameReportPickerToken.all
    @Published var savePickerSelection: String = MultiGameReportPickerToken.all
    @Published var useAllPlayers: Bool = true
    @Published var selectedPlayer: String?
    @Published var useAllSaves: Bool = true
    @Published var selectedSave: String?

    var entries: [(label: String, savesRoot: URL)] = []

    let emptyEntriesMessage: String
    let emptyPlayersMessage: String
    let loadFailurePrefix: String

    public init(
        emptyEntriesMessage: String? = nil,
        emptyPlayersMessage: String? = nil,
        loadFailurePrefix: String? = nil
    ) {
        self.emptyEntriesMessage = emptyEntriesMessage ?? PDKL10n.string(
            "allPlayers.stats.error.emptyEntries"
        )
        self.emptyPlayersMessage = emptyPlayersMessage ?? "No players available for statistics."
        self.loadFailurePrefix = loadFailurePrefix ?? PDKL10n.string(
            "allPlayers.stats.error.loadFailurePrefix"
        )
    }

    public static func entriesSignature(_ entries: [(label: String, savesRoot: URL)]) -> String {
        entries.map { "\($0.label)|\($0.savesRoot.path)" }.joined(separator: "\u{1e}")
    }

    public func configureAndLoad(entries: [(label: String, savesRoot: URL)]) async {
        await configureAndLoad(entries: entries, currentPlayerIDs: nil)
    }

    /// 加载全部玩家报表后，按当前玩家 ID（String，无短杠）过滤。
    public func configureAndLoad(
        entries: [(label: String, savesRoot: URL)],
        currentPlayerIDs: Set<String>?
    ) async {
        self.entries = entries
        contentState = .loading
        do {
            guard entries.isEmpty == false else {
                reports = []
                contentState = .emptySaves
                resetPickers()
                return
            }
            let result = try await MultiGamePlayerReportLoader.loadAllPlayersReports(entries: entries)
            reports = MultiGamePlayerReportFiltering.filterByCurrentPlayerIDs(
                result,
                allowedPlayerIDs: currentPlayerIDs
            )
            if currentPlayerIDs?.isEmpty == true {
                contentState = .emptyPlayers
            } else if reports.isEmpty {
                contentState = .emptySaves
            } else {
                contentState = .loaded
            }
            resetPickers()
        } catch {
            reports = []
            contentState = .failed("\(loadFailurePrefix)\(error.localizedDescription)")
        }
    }

    /// 在统计弹窗关闭时调用，避免上次打开的数据残留到下次展示。
    public func clearForDismiss() {
        reports = []
        contentState = .loading
        entries = []
        resetPickers()
    }

    func filteredReports() -> [MultiGamePlayerReport] {
        let player: String? = useAllPlayers ? nil : selectedPlayer
        let save: String? = useAllSaves ? nil : selectedSave
        return MultiGamePlayerReportFiltering.filter(reports, player: player, save: save)
    }

    /// 供宿主传入展示名排序；内部默认用玩家 ID 前缀排序。
    func sortedPlayerUUIDs(displayName: (String) -> String) -> [String] {
        MultiGamePlayerReportFiltering.sortedPlayerUUIDs(from: reports, displayName: displayName)
    }

    var savePickerOptions: [SavePickerOption] {
        MultiGamePlayerReportFiltering.makeSavePickerOptions(from: reports)
    }

    private func resetPickers() {
        playerPickerSelection = MultiGameReportPickerToken.all
        savePickerSelection = MultiGameReportPickerToken.all
        useAllPlayers = true
        selectedPlayer = nil
        useAllSaves = true
        selectedSave = nil
    }
}

// MARK: - Header（放入 CommonSheetView 的 header，避免被限高 ScrollView 卷动）

public struct AllPlayersMultiGameStatsHeaderContent: View {
    @ObservedObject var controller: AllPlayersMultiGameStatsController
    let title: String
    let playerDisplayName: (String) -> String

    public init(
        controller: AllPlayersMultiGameStatsController,
        title: String? = nil,
        playerDisplayName: @escaping (String) -> String
    ) {
        self.controller = controller
        self.title = title ?? PDKL10n.string("allPlayers.stats.header.title")
        self.playerDisplayName = playerDisplayName
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            headerPickers
        }
    }

    private var headerPickers: some View {
        HStack(spacing: 10) {
            Picker("", selection: $controller.playerPickerSelection) {
                Text(PDKL10n.string("allPlayers.stats.picker.allPlayers"))
                    .tag(MultiGameReportPickerToken.all)
                ForEach(controller.sortedPlayerUUIDs(displayName: playerDisplayName), id: \.self) { playerID in
                    Text(playerDisplayName(playerID)).tag(playerID)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            .help(PDKL10n.string("allPlayers.stats.picker.player.help"))
            .onChange(of: controller.playerPickerSelection) { _, newValue in
                if newValue == MultiGameReportPickerToken.all {
                    controller.useAllPlayers = true
                    controller.selectedPlayer = nil
                } else {
                    controller.useAllPlayers = false
                    controller.selectedPlayer = newValue
                }
            }

            Picker("", selection: $controller.savePickerSelection) {
                Text(PDKL10n.string("allPlayers.stats.picker.allSaves"))
                    .tag(MultiGameReportPickerToken.all)
                ForEach(controller.savePickerOptions) { opt in
                    Text(opt.label).tag(opt.key)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
            .help(PDKL10n.string("allPlayers.stats.picker.save.help"))
            .onChange(of: controller.savePickerSelection) { _, newValue in
                if newValue == MultiGameReportPickerToken.all {
                    controller.useAllSaves = true
                    controller.selectedSave = nil
                } else {
                    controller.useAllSaves = false
                    controller.selectedSave = newValue
                }
            }
        }
    }
}

// MARK: - Body（图表区）

public struct AllPlayersMultiGameStatsReportSection: View {
    @ObservedObject var controller: AllPlayersMultiGameStatsController
    let playerDisplayName: (String) -> String
    let playerAvatarView: (String) -> AnyView

    public init(
        controller: AllPlayersMultiGameStatsController,
        playerDisplayName: @escaping (String) -> String,
        playerAvatarView: @escaping (String) -> AnyView
    ) {
        self.controller = controller
        self.playerDisplayName = playerDisplayName
        self.playerAvatarView = playerAvatarView
    }

    public var body: some View {
        Group {
            switch controller.contentState {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .emptyPlayers:
                Text(controller.emptyPlayersMessage)
                    .foregroundStyle(.secondary)
            case .emptySaves:
                Text(controller.emptyEntriesMessage)
                    .foregroundStyle(.secondary)
            case let .failed(message):
                Text(message)
                    .foregroundStyle(.red)
            case .loaded:
                AllPlayersMultiGameReportView(
                    reports: controller.filteredReports(),
                    playerDisplayName: playerDisplayName,
                    playerAvatarView: playerAvatarView
                )
            }
        }
    }
}

