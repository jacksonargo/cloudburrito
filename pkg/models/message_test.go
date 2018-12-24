package models

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func TestMessage(t *testing.T) {
	assert := assert.New(t)
	mockText := "gendo did nothing wrong"
	mockPatron := NewPatron()
	mockErr := fmt.Errorf("mock error")
	var m *message
	var mt *MockMessageTransport
	var newMocks = func() {
		mt = new(MockMessageTransport)
		m = NewMessage(mockText, mockPatron, mt).(*message)
	}

	// NewMessage()
	newMocks()
	assert.Equal(mockText, m.text)
	assert.Exactly(mockPatron, m.to)
	assert.Exactly(mt, m.transport)

	// m.Text()
	newMocks()
	assert.Equal(m.text, m.Text())

	// m.Send() failure
	newMocks()
	mt.On("Send", m).Return(mockErr)
	assert.Equal(m.Send(), mockErr)
	mt.AssertExpectations(t)

	// m.Send() success
	newMocks()
	mt.On("Send", m).Return(nil)
	start := time.Now()
	assert.NoError(m.Send())
	assert.WithinDuration(time.Now(), m.sent, time.Since(start))
	mt.AssertExpectations(t)
}
