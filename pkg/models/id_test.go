package models

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestID(t *testing.T) {
	assert := assert.New(t)
	var x ID
	// NewID()
	assert.NotEqual(NewID(), NewID(), "ids should be unique")
	// id.ID()
	x = NewID()
	assert.EqualValues(x, x.ID())
	// id.String()
	x = NewID()
	assert.EqualValues(x, x.String())
}
