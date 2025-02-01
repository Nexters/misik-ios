#!/bin/sh

# 프로젝트 디렉토리로 이동
cd "$CI_WORKSPACE"

# 빌드 번호 증가 함수
increment_build_number() {
    echo "$1 배포 중... 빌드 번호 증가 중"

    # 현재 빌드 번호 가져오기
    CURRENT_BUILD_NUMBER=$(agvtool what-version -terse)

    echo "Current Build Number: $CURRENT_BUILD_NUMBER"

    # 빌드 번호 증가
    NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
    agvtool new-version -all $NEW_BUILD_NUMBER

    echo "Updated Build Number: $NEW_BUILD_NUMBER"
}

# 마케팅 버전 증가 함수 (Release 빌드에서만 실행)
increment_marketing_version() {
    echo "Release 배포 중... 마케팅 버전 증가 중"

    # 현재 마케팅 버전 가져오기
    CURRENT_MARKETING_VERSION=$(agvtool what-marketing-version | awk '{print $NF}')

    echo "Current Marketing Version: $CURRENT_MARKETING_VERSION"

    # 마케팅 버전을 Major.Minor.Patch 형태로 분리
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_MARKETING_VERSION"

    # Patch 버전 증가
    PATCH=$((PATCH + 1))

    # 새로운 마케팅 버전 생성
    NEW_MARKETING_VERSION="$MAJOR.$MINOR.$PATCH"

    echo "Updated Marketing Version: $NEW_MARKETING_VERSION"

    # 마케팅 버전 업데이트
    agvtool new-marketing-version $NEW_MARKETING_VERSION
}

# CI_WORKFLOW 값에 따라 실행
case "$CI_WORKFLOW" in
    "TestFlight")
        increment_build_number "TestFlight"
        ;;
    "Release")
        increment_build_number "Release"
        increment_marketing_version
        ;;
    *)
        echo "Do nothing..."
        ;;
esac