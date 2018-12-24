package models

import (
	"github.com/nanobox-io/golang-scribble"
	"sync"
	"time"
)

const LostTime = 1 * time.Hour
const StaleTime = 5 * time.Minute

var _ = scribble.Version

type Pack interface {
	ID() ID
	Latency() time.Duration
	String() string
	IsStale() bool
	TimeAlive() time.Duration
	IsFailed() bool
	Fail() time.Time
	IsReceived() bool
	Receive() time.Time
	IsAssigned() bool
	Assign(Patron) time.Time
	IsEnRoute() bool
	EnRoute() time.Time
	IsLost() bool
}

type pack struct {
	id          ID
	lock        sync.Mutex
	hungryMan   Patron
	deliveryMan Patron
	created     time.Time
	updated     time.Time
	retry       bool
	failed      time.Time
	assigned    time.Time
	enRoute     time.Time
	received    time.Time
	slackParams map[string]string
	forceStale  bool
	staleTime   time.Duration
	lostTime    time.Duration
}

func NewPack(hungryMan Patron) Pack {
	return &pack{
		id:        NewID(),
		created:   time.Now(),
		updated:   time.Now(),
		hungryMan: hungryMan,
		staleTime: StaleTime,
		lostTime:  LostTime,
	}
}

func (x *pack) ID() ID {
	x.lock.Lock()
	defer x.lock.Unlock()
	return x.id
}

func (x *pack) String() string {
	x.lock.Lock()
	defer x.lock.Unlock()
	return x.id.String()
}

func (x *pack) Fail() time.Time {
	x.lock.Lock()
	defer x.lock.Unlock()
	x.failed = time.Now()
	return x.failed
}

func (x *pack) IsFailed() bool {
	x.lock.Lock()
	defer x.lock.Unlock()
	return !x.failed.IsZero()
}

func (x *pack) Assign(deliveryMan Patron) time.Time {
	x.lock.Lock()
	defer x.lock.Unlock()
	x.deliveryMan = deliveryMan
	x.assigned = time.Now()
	return x.assigned
}

func (x *pack) IsAssigned() bool {
	x.lock.Lock()
	defer x.lock.Unlock()
	return !x.assigned.IsZero()
}

func (x *pack) EnRoute() time.Time {
	x.lock.Lock()
	defer x.lock.Unlock()
	x.enRoute = time.Now()
	return x.enRoute
}

func (x *pack) IsEnRoute() bool {
	x.lock.Lock()
	defer x.lock.Unlock()
	return !x.enRoute.IsZero()
}

func (x *pack) Receive() time.Time {
	x.lock.Lock()
	defer x.lock.Unlock()
	x.received = time.Now()
	return x.received
}

func (x *pack) IsReceived() bool {
	x.lock.Lock()
	defer x.lock.Unlock()
	return !x.received.IsZero()
}

func (x *pack) TimeAlive() time.Duration {
	if x.IsReceived() {
		x.lock.Lock()
		defer x.lock.Unlock()
		return x.received.Sub(x.assigned)
	} else if x.IsAssigned() {
		x.lock.Lock()
		defer x.lock.Unlock()
		return time.Since(x.assigned)
	} else {
		return 0
	}
}

func (x *pack) Latency() time.Duration {
	if x.IsFailed() {
		x.lock.Lock()
		defer x.lock.Unlock()
		return x.failed.Sub(x.created)
	} else if x.IsReceived() {
		x.lock.Lock()
		defer x.lock.Unlock()
		return x.received.Sub(x.created)
	} else {
		x.lock.Lock()
		defer x.lock.Unlock()
		return time.Since(x.created)
	}
}

func (x *pack) IsStale() bool {
	if x.IsFailed() {
		return false
	} else if x.IsEnRoute() {
		return false
	} else if x.IsReceived() {
		return false
	} else if !x.IsAssigned() {
		return false
	} else {
		x.lock.Lock()
		defer x.lock.Unlock()
		if x.forceStale {
			return true
		} else {
			return time.Since(x.assigned) > x.staleTime
		}
	}
}

func (x *pack) IsLost() bool {
	if x.IsReceived() {
		return false
	} else if x.IsFailed() {
		return false
	} else if !x.IsAssigned() {
		return false
	} else {
		x.lock.Lock()
		defer x.lock.Unlock()
		return time.Since(x.assigned) > x.lostTime
	}
}
