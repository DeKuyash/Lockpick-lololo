

lololo = lololo or {}
lololo.config = lololo.config or {}
lololo.doors = lololo.doors or {} -- тут хранятся индекс двери - колво пинов, ЕСЛИ КОЛ-ВО пинов НЕ БАЗОВОЕ, а измененное (5+ в дефолтном случае)

lololo.config.nextHit         = lololo.config.nextHit         or 5 -- через сколько секунд можно приступить к новому взлому
lololo.config.defaultPinCount = lololo.config.defaultPinCount or 5 -- сколько пинов базово с самого начала                                                      ! ВНИМАНИЕ ! больше 15 - рекурсия
lololo.config.deathZonePin    = lololo.config.deathZonePin    or 5 -- мертвая зона в мини игре на рег попадания по пинам, типо погрешонсть, я бы не трогал
lololo.config.lockpickCount   = lololo.config.lockpickCount   or 5 -- колво отмычек у типа
lololo.config.minPinCount     = lololo.config.minPinCount     or lololo.config.defaultPinCount + 1 -- сколько минимум можно поставить пинов при изменении настроек двери
lololo.config.maxPinCount     = lololo.config.maxPinCount     or 15 -- тут понятн                                                                               ! ВНИМАНИЕ ! больше 15 - рекурсия