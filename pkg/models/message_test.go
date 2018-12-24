package models

import (
	"fmt"
	"github.com/jacksonargo/cloudburrito/pkg/models/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"testing"
)

func TestMessage(t *testing.T) {
	assert := assert.New(t)
	mockText := "gendo did nothing wrong"
	mockPatron := NewPatron()
	var m *message
	var mt MessageTransport

	// NewMessage()
	mt = &nullTransport{}
	m = NewMessage(mockText, mockPatron, mt).(*message)
	assert.Equal(mockText, m.text)
	assert.Exactly(mockPatron, m.to)
	assert.Exactly(t, m.transport)

	// m.Text()
	m = NewMessage(mockText, mockPatron, nil).(*message)
	assert.Equal(m.text, m.Text())

	// m.Send() failure
	mt = new(mocks.MessageTransport)
	mockErr := fmt.Errorf("mock error")
	t.On("Send", mockPatron).Return(mockErr)
	m = NewMessage(mockText, mockPatron, mt).(*message)
	assert.Equal(m.Send(), mockErr)

	// m.Send() success
	mt = new(mocks.MessageTransport)
	t.On("Send", mock.Anything).Return(nil)
}
