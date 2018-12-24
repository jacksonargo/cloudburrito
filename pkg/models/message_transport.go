package models

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/nlopes/slack"
	"io/ioutil"
	"net/http"
)

type MessageTransport interface {
	Send(Message) error
}

type nullTransport struct{}

func (x *nullTransport) Send(Message) error { return nil }

type slackDmTransport struct{ slack.Client }

func (x *slackDmTransport) Send(Message) error {
	//im = slack_client.im_open(user: to._id).channel.id
	//slack_client.chat_postMessage(channel: im, text: text)
	//log.Println("Sent slack pm to %s.", to)
	return nil
}

type slackUrlTransport struct {
	ResponseType string
	ResponseUrl  string
}

func NewSlackUrlTransport(responseType, responseUrl string) *slackUrlTransport {
	return &slackUrlTransport{
		ResponseType: responseType,
		ResponseUrl:  responseUrl,
	}
}

type chatResponseMessage struct {
	ResponseType string `json:"response_type"`
	Text         string `json:"text"`
}

func (x *slackUrlTransport) Send(m Message) error {
	client := &http.Client{}
	body, _ := json.Marshal(&chatResponseMessage{x.ResponseType, m.Text()})
	req, err := http.NewRequest(http.MethodPost, x.ResponseUrl, bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	req.Header.Add("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		body, _ := ioutil.ReadAll(resp.Body)
		return fmt.Errorf("server returned status %s: %s", resp.Status, body)
	}
	return nil
}
