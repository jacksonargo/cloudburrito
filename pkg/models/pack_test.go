package models

import (
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func TestPack(t *testing.T) {
	assert := assert.New(t)
	hungryMan := NewPatron()
	var p *pack
	var now time.Time

	// NewPack
	p = NewPack(hungryMan).(*pack)
	assert.NotEmpty(p.id)
	assert.NotEmpty(p.created)
	assert.NotEmpty(p.updated)
	assert.Exactly(p.hungryMan, hungryMan)
	assert.Equal(p.staleTime, StaleTime)
	assert.Equal(p.lostTime, LostTime)
	assert.Zero(p.failed)
	assert.Zero(p.assigned)
	assert.Zero(p.enRoute)
	assert.Zero(p.received)

	// p.ID()
	p = NewPack(hungryMan).(*pack)
	assert.Equal(p.id, p.ID())

	// p.String()
	p = NewPack(hungryMan).(*pack)
	assert.Equal(p.id.String(), p.String())

	// p.Fail()
	p = NewPack(hungryMan).(*pack)
	now = time.Now()
	assert.Equal(p.Fail(), p.failed)
	assert.NotZero(p.failed)
	assert.WithinDuration(now, p.failed, time.Now().Sub(now))

	// p.IsFailed()
	// when failed
	p = NewPack(hungryMan).(*pack)
	p.Fail()
	assert.True(p.IsFailed())
	// when not failed
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsFailed())

	// p.Assign()
	p = NewPack(hungryMan).(*pack)
	now = time.Now()
	assert.Equal(p.Assign(hungryMan), p.assigned)
	assert.NotZero(p.assigned)
	assert.Exactly(hungryMan, p.deliveryMan)
	assert.WithinDuration(now, p.assigned, time.Now().Sub(now))

	// p.IsAssigned()
	// when assigned
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	assert.True(p.IsAssigned())
	// when not failed
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsAssigned())

	// p.EnRoute()
	p = NewPack(hungryMan).(*pack)
	now = time.Now()
	assert.Equal(p.EnRoute(), p.enRoute)
	assert.NotZero(p.enRoute)
	assert.WithinDuration(now, p.enRoute, time.Now().Sub(now))

	// p.IsEnRoute()
	// when en route
	p = NewPack(hungryMan).(*pack)
	p.EnRoute()
	assert.True(p.IsEnRoute())
	// when not en route
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsEnRoute())

	// p.Receive()
	p = NewPack(hungryMan).(*pack)
	now = time.Now()
	assert.Equal(p.Receive(), p.received)
	assert.NotZero(p.received)
	assert.WithinDuration(now, p.received, time.Now().Sub(now))

	// p.IsReceived()
	// when received
	p = NewPack(hungryMan).(*pack)
	p.Receive()
	assert.True(p.IsReceived())
	// when not received
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsReceived())

	// p.TimeAlive()
	// when recevied, assigned
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	p.Receive()
	assert.Equal(p.received.Sub(p.assigned), p.TimeAlive())
	// when assigend
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	assert.NotZero(p.TimeAlive())
	// when unassigned
	p = NewPack(hungryMan).(*pack)
	assert.Zero(p.TimeAlive())

	// p.Latency()
	// when failed
	p = NewPack(hungryMan).(*pack)
	p.Fail()
	assert.Equal(p.failed.Sub(p.created), p.Latency())
	// when received
	p = NewPack(hungryMan).(*pack)
	p.Receive()
	assert.Equal(p.received.Sub(p.created), p.Latency())
	// otherwise
	p = NewPack(hungryMan).(*pack)
	now = time.Now()
	assert.InDelta(now.Sub(p.created), p.Latency(), float64(time.Now().Sub(now)))

	// p.IsStale()
	// when failed
	p = NewPack(hungryMan).(*pack)
	p.Fail()
	assert.False(p.IsStale())
	// when en route
	p = NewPack(hungryMan).(*pack)
	p.EnRoute()
	assert.False(p.IsStale())
	// when received
	p = NewPack(hungryMan).(*pack)
	p.Receive()
	assert.False(p.IsStale())
	// when unassigned
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsStale())
	// when assigned and forced stale
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	p.forceStale = true
	assert.True(p.IsStale())
	// when assigned and not stale
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	assert.False(p.IsStale())
	// when assigned and stale
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	p.assigned = time.Now().Add(-p.staleTime)
	assert.True(p.IsStale())

	// p.IsLost()
	// when failed
	p = NewPack(hungryMan).(*pack)
	p.Fail()
	assert.False(p.IsLost())
	// when received
	p = NewPack(hungryMan).(*pack)
	p.Receive()
	assert.False(p.IsLost())
	// when not assigned
	p = NewPack(hungryMan).(*pack)
	assert.False(p.IsLost())
	// when assigned and not lost
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	assert.False(p.IsLost())
	// when assigned and lost
	p = NewPack(hungryMan).(*pack)
	p.Assign(hungryMan)
	p.assigned = time.Now().Add(-p.lostTime)
	assert.True(p.IsLost())
}
