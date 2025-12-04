package test

import (
    "testing"
)

func TestMyRegionVariable(t *testing.T) {
    // Variable para testear
    myregion := "us-east-1"

    // Validar el valor
    if myregion != "us-east-1" {
        t.Errorf("Se esperaba 'us-east-1', pero se obtuvo '%s'", myregion)
    }
}