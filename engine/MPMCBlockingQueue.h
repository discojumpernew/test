#ifndef MPMCBLOCKINGQUEUE_H
#define MPMCBLOCKINGQUEUE_H

#include <QMutex>
#include <QQueue>
#include <QWaitCondition>

template <typename T>
class MPMCBlockingQueue {
public:
    void push(T value)
    {
        QMutexLocker locker(&mutex_);

        queue_.append(std::move(value));
        cond_.wakeOne();
    }

    T take()
    {
        QMutexLocker locker(&mutex_);

        while (queue_.isEmpty())
            cond_.wait(&mutex_);

        return queue_.dequeue();
    }

    void removeIf(std::function<bool(const T&)> pred)
    {
        QMutexLocker locker(&mutex_);

        for (int i = 0; i < queue_.size(); ++i) {
            if (pred(queue_[i])) {
                queue_.removeAt(i);
            }
        }
    }

private:
    QQueue<T> queue_;
    QMutex mutex_;
    QWaitCondition cond_;
};

#endif // MPMCBLOCKINGQUEUE_H
