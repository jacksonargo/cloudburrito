package models

type Patron interface{}

type patron struct{}

func NewPatron() Patron { return &patron{} }
