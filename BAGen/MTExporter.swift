//
//  MTExporter.swift
//  BAGen
//
//  Created by memz233 on 7/18/24.
//

class MTExporter {
    static let shared = MTExporter()
    
    func splitChatData(in chatDatas: [MTBase.SingleChatData], by method: ImageExportSplittingMethod) -> [[MTBase.SingleChatData]] {
        switch method {
        case .none:
            return [chatDatas]
        case .byCharacter:
            var tmpReturnChatData = [[MTBase.SingleChatData]]()
            var tmpChatDataSplitting = [MTBase.SingleChatData]()
            for chatData in chatDatas {
                if let cdl = tmpChatDataSplitting.last {
                    if chatData.characterId == cdl.characterId {
                        tmpChatDataSplitting.append(chatData)
                    } else {
                        tmpReturnChatData.append(tmpChatDataSplitting)
                        tmpChatDataSplitting.removeAll()
                        tmpChatDataSplitting.append(chatData)
                    }
                } else {
                    tmpChatDataSplitting.append(chatData)
                }
            }
            if !tmpChatDataSplitting.isEmpty {
                tmpReturnChatData.append(tmpChatDataSplitting)
            }
            return tmpReturnChatData
        case .byIndex(let interval):
            var tmpReturnChatData = [[MTBase.SingleChatData]]()
            var addedCount = 0
            var tmpChatDataSplitting = [MTBase.SingleChatData]()
            for chatData in chatDatas {
                if addedCount == interval {
                    tmpReturnChatData.append(tmpChatDataSplitting)
                    tmpChatDataSplitting.removeAll()
                    addedCount = 0
                }
                tmpChatDataSplitting.append(chatData)
                addedCount += 1
            }
            if !tmpChatDataSplitting.isEmpty {
                tmpReturnChatData.append(tmpChatDataSplitting)
            }
            return tmpReturnChatData
        }
    }
    
    enum ImageExportSplittingMethod: Equatable {
        case none
        case byCharacter
        case byIndex(Int)
    }
}
