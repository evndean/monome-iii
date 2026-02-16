grid_led_all(0)
grid_refresh()

function grid(x,y,z) -- callback for grid keypresses. example to print key data:
    ps("grid %d %d %d",x,y,z)
    grid_led(x,y,z*3+1)
    grid_refresh()
end
