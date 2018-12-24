package models

import "github.com/satori/go.uuid"

type ID interface {
	ID() string
	String() string
}

type id string

func NewID() ID             { return id(uuid.Must(uuid.NewV4()).String()) }
func (x id) ID() string     { return string(x) }
func (x id) String() string { return string(x) }
