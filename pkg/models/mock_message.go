// Code generated by mockery v1.0.0. DO NOT EDIT.

package models

import mock "github.com/stretchr/testify/mock"

// MockMessage is an autogenerated mock type for the Message type
type MockMessage struct {
	mock.Mock
}

// Send provides a mock function with given fields:
func (_m *MockMessage) Send() error {
	ret := _m.Called()

	var r0 error
	if rf, ok := ret.Get(0).(func() error); ok {
		r0 = rf()
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// Text provides a mock function with given fields:
func (_m *MockMessage) Text() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}