package models

import (
	"bytes"
	"encoding/json"
	"github.com/nlopes/slack"
	"net/http"
	"time"
)

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

type MessageTransport interface {
	Send(Message) error
}

type nullTransport struct{}

func (x *nullTransport) Send(Message) error { return nil }

type slackDM struct{ slack.Client }

func (x *slackDM) Send(Message) error {
	//im = slack_client.im_open(user: to._id).channel.id
	//slack_client.chat_postMessage(channel: im, text: text)
	//log.Println("Sent slack pm to %s.", to)
	return nil
}

type slackURLResponse struct {
	responseType string
	responseURL  string
}

func NewSlackURLResponse(responseType, responseURL string) *slackURLResponse {
	return &slackURLResponse{responseType, responseURL}
}

func (x *slackURLResponse) Send(m Message) error {
	client := &http.Client{}
	payload := map[string]string{"response_type": x.responseType, "text": m.Text()}
	if body, err := json.Marshal(payload); err != nil {
		return err
	} else if req, err := http.NewRequest(http.MethodPost, x.responseURL, bytes.NewBuffer(body)); err != nil {
		return err
	} else {
		req.Header.Add("Content-Type", "application/json")
		_, err := client.Do(req)
		return err
	}
}
