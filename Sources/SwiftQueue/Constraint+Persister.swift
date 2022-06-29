// The MIT License (MIT)
//
// Copyright (c) 2022 Lucas Nelaupe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

internal class PersisterConstraint: SimpleConstraint {

    private let serializer: JobInfoSerializer

    private let persister: JobPersister

    init(serializer: JobInfoSerializer, persister: JobPersister) {
        self.serializer = serializer
        self.persister = persister
    }

    override func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {
        let data = try serializer.serialize(info: operation.info)
        let name = operation.name ?? ""
        let queueName = queue.name ?? ""
        assertNotEmptyString(name)
        assertNotEmptyString(queueName)
        persister.put(queueName: queueName, taskId: name, data: data)
    }

    func remove(queueName: String, taskId: String) {
        persister.remove(queueName: queueName, taskId: taskId)
    }

}
