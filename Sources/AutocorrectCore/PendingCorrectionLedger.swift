import Foundation

public struct PendingCorrectionID: Hashable, Sendable {
    fileprivate let rawValue: UUID

    public init() {
        self.rawValue = UUID()
    }
}

public struct PendingCorrection: Equatable, Sendable {
    public let id: PendingCorrectionID
    public let original: String
    public let range: NSRange

    public init(id: PendingCorrectionID, original: String, range: NSRange) {
        self.id = id
        self.original = original
        self.range = range
    }
}

public struct PendingCorrectionLedger {
    private var jobs: [PendingCorrectionID: PendingCorrection] = [:]

    public init() {}

    public var count: Int {
        jobs.count
    }

    @discardableResult
    public mutating func register(original: String, range: NSRange) -> PendingCorrectionID {
        let id = PendingCorrectionID()
        jobs[id] = PendingCorrection(id: id, original: original, range: range)
        return id
    }

    public func job(for id: PendingCorrectionID) -> PendingCorrection? {
        jobs[id]
    }

    public mutating func cancel(_ id: PendingCorrectionID) {
        jobs.removeValue(forKey: id)
    }

    public mutating func cancelAll() {
        jobs.removeAll(keepingCapacity: false)
    }

    /// Records a mutation that has already been committed to the client document.
    /// Jobs entirely after the mutation are shifted by the mutation delta. Jobs that
    /// overlap the mutation are discarded because their logical target is no longer
    /// provably valid.
    public mutating func recordMutation(_ mutation: TextMutation) {
        rebaseOutstandingJobs(across: mutation, excluding: nil)
    }

    /// Commits a successful correction and rebases all other pending jobs around it.
    @discardableResult
    public mutating func commit(
        _ id: PendingCorrectionID,
        replacementUTF16Length: Int
    ) -> TextMutation? {
        guard let completed = jobs.removeValue(forKey: id) else {
            return nil
        }

        let mutation = TextMutation(
            range: completed.range,
            replacementUTF16Length: replacementUTF16Length
        )
        rebaseOutstandingJobs(across: mutation, excluding: id)
        return mutation
    }

    private mutating func rebaseOutstandingJobs(
        across mutation: TextMutation,
        excluding excludedID: PendingCorrectionID?
    ) {
        var rebased: [PendingCorrectionID: PendingCorrection] = [:]
        rebased.reserveCapacity(jobs.count)

        for (id, job) in jobs {
            if id == excludedID {
                rebased[id] = job
                continue
            }

            guard let newRange = TextRangeRebaser.rebase(job.range, across: mutation) else {
                continue
            }

            rebased[id] = PendingCorrection(
                id: job.id,
                original: job.original,
                range: newRange
            )
        }

        jobs = rebased
    }
}
