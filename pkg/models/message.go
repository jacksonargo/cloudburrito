package models

import "time"

type Message interface {
	Send() error
	Text() string
}

type message struct {
	text      string
	to        Patron
	sent      time.Time
	transport MessageTransport
}

func NewMessage(text string, to Patron, via MessageTransport) Message {
	return &message{text: text, to: to, transport: via}
}

func (x *message) Text() string { return x.text }

func (x *message) Send() error {
	if err := x.transport.Send(x); err != nil {
		return err
	}
	x.sent = time.Now()
	return nil
}
