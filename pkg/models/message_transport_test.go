package models

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNullTransport(t *testing.T) {
	assert.NoError(t, (&nullTransport{}).Send(nil))
}

func TestSlackUrlTransport(t *testing.T) {
	assert := assert.New(t)
	mockResponseType := "shougoki"
	mockText := "gendo did nothing wrong"
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/success":
			body, _ := ioutil.ReadAll(r.Body)
			assert.Equal(fmt.Sprintf(`{"response_type":"%s","text":"%s"}`,
				mockResponseType, mockText), string(body))
		case "/failure":
			w.WriteHeader(http.StatusBadRequest)
		default:
			t.Errorf("unrecognized request to test server")
		}
	}))
	defer ts.Close()
	var st *slackUrlTransport
	var m *MockMessage
	var newMocks = func() {
		m = new(MockMessage)
		st = NewSlackUrlTransport(mockResponseType, ts.URL)
	}
	//payload := map[string]string{"response_type": x.ResponseType, "text": m.Text()}

	// NewSlackUrlTransport
	newMocks()
	assert.Equal(mockResponseType, st.ResponseType)
	assert.Equal(ts.URL, st.ResponseUrl)

	// st.Send()
	// with bad url
	newMocks()
	st.ResponseUrl = ts.URL + "bad-url"
	m.On("Text").Return(mockText)
	assert.NoError(st.Send(m))
	// with failure
	newMocks()
	st.ResponseUrl = ts.URL + "/failure"
	m.On("Text").Return(mockText)
	assert.Error(st.Send(m))
	// with success
	newMocks()
	st.ResponseUrl = ts.URL + "/success"
	m.On("Text").Return(mockText)
	assert.Error(st.Send(m))

}
